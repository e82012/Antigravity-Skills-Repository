/**
 * evaluate_candidates.cl
 * 
 * 幾何圖元擬合平行評估 OpenCL Kernel 範例。
 * 本核心實作了：
 * 1. 候選圖元 (Candidates) 的平行評估評分 (1 work-item = 1 候選圖元)
 * 2. 邊緣引導採樣權重獎勵 (Edge-Aware Scoring)
 * 3. 圖像 Alpha Blending 與最優色彩 (Closed-Form Optimal Color) 的計算
 */

// 定義 RGBA 的權重，人眼對綠色最敏感
#define COLOR_WEIGHT_R 0.299f
#define COLOR_WEIGHT_G 0.587f
#define COLOR_WEIGHT_B 0.114f

/**
 * 檢查一個像素是否落在給定的橢圓形狀內
 */
inline bool isPointInEllipse(float x, float y, float cx, float cy, float rx, float ry, float angle_cos, float angle_sin) {
    // 轉化至以橢圓中心為原點的座標系
    float dx = x - cx;
    float dy = y - cy;
    
    // 進行逆旋轉
    float rotated_x = dx * angle_cos + dy * angle_sin;
    float rotated_y = -dx * angle_sin + dy * angle_cos;
    
    // 橢圓方程式：(x/rx)^2 + (y/ry)^2 <= 1.0
    return ((rotated_x * rotated_x) / (rx * rx) + (rotated_y * rotated_y) / (ry * ry)) <= 1.0f;
}

/**
 * 評估單個候選圖元的 Kernel
 */
__kernel void evaluateCandidates(
    __global const uchar4* target,      // 原始目標圖像 (CL_MEM_READ_ONLY)
    __global const uchar4* canvas,      // 當前畫布圖像 (CL_MEM_READ_ONLY)
    __global const float8* candidates,  // 候選圖元數組: [cx, cy, rx, ry, cos, sin, unuse1, unuse2]
    __global float* scores,             // 輸出評分數組 (CL_MEM_WRITE_ONLY)
    const int width,
    const int height,
    __global const float* edgeMap,      // Sobel 邊緣圖 (0.0~1.0, CL_MEM_READ_ONLY)
    const float edgeWeight              // 邊緣引導權重 (0.0~5.0)
) {
    int id = get_global_id(0); // 當前評估的候選圖元索引
    
    // 讀取當前 work-item 負責的圖元參數
    float8 candidate = candidates[id];
    float cx = candidate.s0;
    float cy = candidate.s1;
    float rx = candidate.s2;
    float ry = candidate.s3;
    float cos_a = candidate.s4;
    float sin_a = candidate.s5;
    
    // 計算該圖元的邊界範圍 (AABB) 用以加速像素迭代
    // 這裡使用簡化的半徑範圍包裹矩形
    float max_r = (rx > ry) ? rx : ry;
    int x_start = (int)clamp(cx - max_r, 0.0f, (float)(width - 1));
    int x_end   = (int)clamp(cx + max_r, 0.0f, (float)(width - 1));
    int y_start = (int)clamp(cy - max_r, 0.0f, (float)(height - 1));
    int y_end   = (int)clamp(cy + max_r, 0.0f, (float)(height - 1));
    
    double errorSumBefore = 0.0;
    double errorSumAfter = 0.0;
    
    double edgeSum = 0.0;
    int coveredPixels = 0;
    
    // 色彩最優解的閉合求解累加器
    double sumTargetR = 0.0, sumTargetG = 0.0, sumTargetB = 0.0;
    
    // 1. 第一階段：計算形狀覆蓋區域內的像素統計與最優色彩閉合解
    for (int y = y_start; y <= y_end; y++) {
        for (int x = x_start; x <= x_end; x++) {
            if (isPointInEllipse((float)x, (float)y, cx, cy, rx, ry, cos_a, sin_a)) {
                int idx = y * width + x;
                uchar4 t_pix = target[idx];
                
                sumTargetR += t_pix.x;
                sumTargetG += t_pix.y;
                sumTargetB += t_pix.z;
                
                if (edgeWeight > 0.0f) {
                    edgeSum += edgeMap[idx];
                }
                coveredPixels++;
            }
        }
    }
    
    // 若沒有覆蓋任何像素，給予極差分數
    if (coveredPixels == 0) {
        scores[id] = -1e9f;
        return;
    }
    
    // 2. 第二階段：求解最優色彩並模擬 Over Blending 後計算殘差改善度
    // 此處假設 alpha 混合度為常數 0.6f (Forza Painter 常用區間)
    float alpha = 0.6f;
    float optR = (float)(sumTargetR / coveredPixels);
    float optG = (float)(sumTargetG / coveredPixels);
    float optB = (float)(sumTargetB / coveredPixels);
    
    for (int y = y_start; y <= y_end; y++) {
        for (int x = x_start; x <= x_end; x++) {
            if (isPointInEllipse((float)x, (float)y, cx, cy, rx, ry, cos_a, sin_a)) {
                int idx = y * width + x;
                uchar4 t_pix = target[idx];
                uchar4 c_pix = canvas[idx];
                
                // 模擬混合後的顏色 (Over Operator)
                float blendedR = optR * alpha + c_pix.x * (1.0f - alpha);
                float blendedG = optG * alpha + c_pix.y * (1.0f - alpha);
                float blendedB = optB * alpha + c_pix.z * (1.0f - alpha);
                
                // 計算混合前的加權 MSE 殘差
                float diffBeforeR = (float)t_pix.x - c_pix.x;
                float diffBeforeG = (float)t_pix.y - c_pix.y;
                float diffBeforeB = (float)t_pix.z - c_pix.z;
                errorSumBefore += (diffBeforeR * diffBeforeR * COLOR_WEIGHT_R) +
                                  (diffBeforeG * diffBeforeG * COLOR_WEIGHT_G) +
                                  (diffBeforeB * diffBeforeB * COLOR_WEIGHT_B);
                
                // 計算混合後的加權 MSE 殘差
                float diffAfterR = (float)t_pix.x - blendedR;
                float diffAfterG = (float)t_pix.y - blendedG;
                float diffAfterB = (float)t_pix.z - blendedB;
                errorSumAfter += (diffAfterR * diffAfterR * COLOR_WEIGHT_R) +
                                 (diffAfterG * diffAfterG * COLOR_WEIGHT_G) +
                                 (diffAfterB * diffAfterB * COLOR_WEIGHT_B);
            }
        }
    }
    
    // 3. 第三階段：計算最終分數，融合邊緣覆蓋獎勵
    float baseDelta = (float)(errorSumBefore - errorSumAfter);
    float edgeReward = 0.0f;
    
    if (edgeWeight > 0.0f) {
        float avgEdge = (float)(edgeSum / coveredPixels);
        edgeReward = avgEdge * edgeWeight * 255.0f; // 縮放至同等量級
    }
    
    // 分數越高代表該候選越優秀 (能減少越多的 MSE，或大幅貼合邊緣)
    scores[id] = baseDelta + edgeReward;
}
