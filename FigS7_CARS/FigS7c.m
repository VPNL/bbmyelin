% Correlation Analysis: MBP vs CARS Myelin Sheaths
% Pearson and Spearman correlations with visualization
% Author: [Your Name]
% Date: [Current Date]
% MATLAB Version: 2024b

%% Clear workspace
clear; clc; close all;

%% Load data
data = readtable('FigS7c.csv');

%% Display data summary
fprintf('========================================\n');
fprintf('CORRELATION ANALYSIS: MBP vs CARS\n');
fprintf('========================================\n\n');

fprintf('Dataset Summary:\n');
fprintf('----------------\n');
fprintf('Total observations: %d\n', height(data));
fprintf('Variables: myelin_sheaths_MBP, myelin_sheaths_CARS\n\n');

% Display first few rows
fprintf('First 10 rows of data:\n');
disp(head(data, 10));

%% Extract variables
x = data.myelin_sheaths_CARS;  % X-axis
y = data.myelin_sheaths_MBP;   % Y-axis

%% Check for missing data
missing_x = sum(isnan(x));
missing_y = sum(isnan(y));

fprintf('\nMissing Data:\n');
fprintf('-------------\n');
fprintf('Missing values in myelin_sheaths_CARS: %d\n', missing_x);
fprintf('Missing values in myelin_sheaths_MBP: %d\n', missing_y);

% Remove missing data
valid_idx = ~isnan(x) & ~isnan(y);
x_clean = x(valid_idx);
y_clean = y(valid_idx);

fprintf('Valid observations for correlation: %d\n\n', sum(valid_idx));

%% Descriptive statistics
fprintf('Descriptive Statistics:\n');
fprintf('----------------------\n');
fprintf('myelin_sheaths_CARS (X-axis):\n');
fprintf('  Mean: %.4f\n', mean(x_clean));
fprintf('  Median: %.4f\n', median(x_clean));
fprintf('  SD: %.4f\n', std(x_clean));
fprintf('  Range: [%.4f, %.4f]\n\n', min(x_clean), max(x_clean));

fprintf('myelin_sheaths_MBP (Y-axis):\n');
fprintf('  Mean: %.4f\n', mean(y_clean));
fprintf('  Median: %.4f\n', median(y_clean));
fprintf('  SD: %.4f\n', std(y_clean));
fprintf('  Range: [%.4f, %.4f]\n\n', min(y_clean), max(y_clean));

%% Pearson Correlation
fprintf('========================================\n');
fprintf('PEARSON CORRELATION\n');
fprintf('========================================\n\n');

[r_pearson, p_pearson] = corr(x_clean, y_clean, 'Type', 'Pearson');

fprintf('Pearson correlation coefficient (r): %.4f\n', r_pearson);
fprintf('p-value: %.6e\n', p_pearson);
fprintf('R² (coefficient of determination): %.4f\n', r_pearson^2);

if p_pearson < 0.001
    fprintf('Significance: p < 0.001 ***\n\n');
elseif p_pearson < 0.01
    fprintf('Significance: p < 0.01 **\n\n');
elseif p_pearson < 0.05
    fprintf('Significance: p < 0.05 *\n\n');
else
    fprintf('Significance: Not significant (p ≥ 0.05)\n\n');
end

%% Spearman Correlation
fprintf('========================================\n');
fprintf('SPEARMAN CORRELATION\n');
fprintf('========================================\n\n');

[r_spearman, p_spearman] = corr(x_clean, y_clean, 'Type', 'Spearman');

fprintf('Spearman correlation coefficient (ρ): %.4f\n', r_spearman);
fprintf('p-value: %.6e\n', p_spearman);

if p_spearman < 0.001
    fprintf('Significance: p < 0.001 ***\n\n');
elseif p_spearman < 0.01
    fprintf('Significance: p < 0.01 **\n\n');
elseif p_spearman < 0.05
    fprintf('Significance: p < 0.05 *\n\n');
else
    fprintf('Significance: Not significant (p ≥ 0.05)\n\n');
end

%% Linear regression
fprintf('========================================\n');
fprintf('LINEAR REGRESSION\n');
fprintf('========================================\n\n');

% Fit linear model
mdl = fitlm(x_clean, y_clean);

fprintf('Linear Model: y = %.4f + %.4f * x\n', mdl.Coefficients.Estimate(1), mdl.Coefficients.Estimate(2));
fprintf('Intercept: %.4f (SE = %.4f, p = %.6e)\n', ...
    mdl.Coefficients.Estimate(1), mdl.Coefficients.SE(1), mdl.Coefficients.pValue(1));
fprintf('Slope: %.4f (SE = %.4f, p = %.6e)\n', ...
    mdl.Coefficients.Estimate(2), mdl.Coefficients.SE(2), mdl.Coefficients.pValue(2));
fprintf('R²: %.4f\n', mdl.Rsquared.Ordinary);
fprintf('Adjusted R²: %.4f\n', mdl.Rsquared.Adjusted);
fprintf('RMSE: %.4f\n\n', mdl.RMSE);

% Display full model
disp(mdl);

%% Create scatter plot with regression line
fprintf('Creating correlation plot...\n');

figure('Position', [100, 100, 800, 700]);

% Scatter plot
scatter(x_clean, y_clean, 50, [0.3, 0.6, 0.9], 'filled', 'MarkerFaceAlpha', 0.6);
hold on;

% Add regression line
x_fit = linspace(min(x_clean), max(x_clean), 100);
y_fit = mdl.Coefficients.Estimate(1) + mdl.Coefficients.Estimate(2) * x_fit;
plot(x_fit, y_fit, 'r-', 'LineWidth', 2);

% Add 95% confidence interval
[y_pred, y_ci] = predict(mdl, x_fit');
plot(x_fit, y_ci(:,1), 'r--', 'LineWidth', 1);
plot(x_fit, y_ci(:,2), 'r--', 'LineWidth', 1);

% Add unity line (y=x) for reference
x_range = [min([x_clean; y_clean]), max([x_clean; y_clean])];
plot(x_range, x_range, 'k--', 'LineWidth', 1);

hold off;

% Format plot
xlabel('Myelin Sheaths - CARS', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Myelin Sheaths - MBP', 'FontSize', 12, 'FontWeight', 'bold');
title('Correlation: MBP vs CARS Myelin Sheaths', 'FontSize', 14, 'FontWeight', 'bold');

% Add statistics to plot
text_x = min(x_clean) + 0.05 * range(x_clean);
text_y = max(y_clean) - 0.05 * range(y_clean);

if p_pearson < 0.001
    sig_str = '***';
elseif p_pearson < 0.01
    sig_str = '**';
elseif p_pearson < 0.05
    sig_str = '*';
else
    sig_str = 'ns';
end

stats_text = sprintf('r = %.3f %s\nR² = %.3f\nn = %d\np = %.2e', ...
    r_pearson, sig_str, r_pearson^2, length(x_clean), p_pearson);
text(text_x, text_y, stats_text, 'FontSize', 11, 'BackgroundColor', 'white', ...
     'EdgeColor', 'black', 'VerticalAlignment', 'top');

% Add legend
legend({'Data', 'Regression line', '95% CI', '95% CI', 'Unity (y=x)'}, ...
       'Location', 'southeast', 'FontSize', 10);

grid on;
axis equal;
set(gca, 'GridAlpha', 0.3);

% Save figure
saveas(gcf, 'MBP_CARS_Correlation.png');
saveas(gcf, 'MBP_CARS_Correlation.fig');

fprintf('Plot saved as "MBP_CARS_Correlation.png" and "MBP_CARS_Correlation.fig"\n\n');

%% Residual diagnostics
fprintf('========================================\n');
fprintf('RESIDUAL DIAGNOSTICS\n');
fprintf('========================================\n\n');

% Create residual plots
figure('Position', [150, 150, 1200, 400]);

% Residuals vs Fitted
subplot(1, 3, 1);
plotResiduals(mdl, 'fitted');
title('Residuals vs Fitted Values', 'FontSize', 11, 'FontWeight', 'bold');

% Q-Q plot
subplot(1, 3, 2);
plotResiduals(mdl, 'probability');
title('Normal Q-Q Plot', 'FontSize', 11, 'FontWeight', 'bold');

% Histogram of residuals
subplot(1, 3, 3);
plotResiduals(mdl, 'histogram');
title('Histogram of Residuals', 'FontSize', 11, 'FontWeight', 'bold');

% Save diagnostics
saveas(gcf, 'MBP_CARS_Residual_Diagnostics.png');
saveas(gcf, 'MBP_CARS_Residual_Diagnostics.fig');

fprintf('Residual diagnostics saved as "MBP_CARS_Residual_Diagnostics.png"\n\n');

%% Test for normality of residuals
[h_sw, p_sw] = swtest(mdl.Residuals.Raw);  % Shapiro-Wilk test

fprintf('Shapiro-Wilk test for normality of residuals:\n');
fprintf('  W-statistic: %.4f\n', 1-h_sw);
fprintf('  p-value: %.6f\n', p_sw);
if p_sw < 0.05
    fprintf('  Residuals are NOT normally distributed (p < 0.05)\n\n');
else
    fprintf('  Residuals are normally distributed (p ≥ 0.05)\n\n');
end

%% Save results to text file
fprintf('Saving results to text file...\n');

fid = fopen('MBP_CARS_Correlation_Results.txt', 'w');
fprintf(fid, '========================================================\n');
fprintf(fid, 'CORRELATION ANALYSIS: MBP vs CARS Myelin Sheaths\n');
fprintf(fid, '========================================================\n\n');

fprintf(fid, 'Dataset: FigS7c.csv\n');
fprintf(fid, 'Date: %s\n\n', datestr(now));

fprintf(fid, 'Sample Size:\n');
fprintf(fid, '  Total observations: %d\n', height(data));
fprintf(fid, '  Valid observations: %d\n\n', length(x_clean));

fprintf(fid, 'Descriptive Statistics:\n');
fprintf(fid, '----------------------\n');
fprintf(fid, 'myelin_sheaths_CARS:\n');
fprintf(fid, '  Mean ± SD: %.4f ± %.4f\n', mean(x_clean), std(x_clean));
fprintf(fid, '  Median: %.4f\n', median(x_clean));
fprintf(fid, '  Range: [%.4f, %.4f]\n\n', min(x_clean), max(x_clean));

fprintf(fid, 'myelin_sheaths_MBP:\n');
fprintf(fid, '  Mean ± SD: %.4f ± %.4f\n', mean(y_clean), std(y_clean));
fprintf(fid, '  Median: %.4f\n', median(y_clean));
fprintf(fid, '  Range: [%.4f, %.4f]\n\n', min(y_clean), max(y_clean));

fprintf(fid, 'Pearson Correlation:\n');
fprintf(fid, '-------------------\n');
fprintf(fid, '  r = %.4f\n', r_pearson);
fprintf(fid, '  R² = %.4f\n', r_pearson^2);
fprintf(fid, '  p-value = %.6e\n', p_pearson);
if p_pearson < 0.001
    fprintf(fid, '  Significance: p < 0.001 ***\n\n');
elseif p_pearson < 0.01
    fprintf(fid, '  Significance: p < 0.01 **\n\n');
elseif p_pearson < 0.05
    fprintf(fid, '  Significance: p < 0.05 *\n\n');
else
    fprintf(fid, '  Significance: Not significant\n\n');
end

fprintf(fid, 'Spearman Correlation:\n');
fprintf(fid, '--------------------\n');
fprintf(fid, '  ρ = %.4f\n', r_spearman);
fprintf(fid, '  p-value = %.6e\n', p_spearman);
if p_spearman < 0.001
    fprintf(fid, '  Significance: p < 0.001 ***\n\n');
elseif p_spearman < 0.01
    fprintf(fid, '  Significance: p < 0.01 **\n\n');
elseif p_spearman < 0.05
    fprintf(fid, '  Significance: p < 0.05 *\n\n');
else
    fprintf(fid, '  Significance: Not significant\n\n');
end

fprintf(fid, 'Linear Regression:\n');
fprintf(fid, '-----------------\n');
fprintf(fid, '  Model: y = %.4f + %.4f * x\n', mdl.Coefficients.Estimate(1), mdl.Coefficients.Estimate(2));
fprintf(fid, '  Intercept: %.4f (SE = %.4f, p = %.6e)\n', ...
    mdl.Coefficients.Estimate(1), mdl.Coefficients.SE(1), mdl.Coefficients.pValue(1));
fprintf(fid, '  Slope: %.4f (SE = %.4f, p = %.6e)\n', ...
    mdl.Coefficients.Estimate(2), mdl.Coefficients.SE(2), mdl.Coefficients.pValue(2));
fprintf(fid, '  R²: %.4f\n', mdl.Rsquared.Ordinary);
fprintf(fid, '  Adjusted R²: %.4f\n', mdl.Rsquared.Adjusted);
fprintf(fid, '  RMSE: %.4f\n\n', mdl.RMSE);

fprintf(fid, 'Residual Diagnostics:\n');
fprintf(fid, '--------------------\n');
fprintf(fid, '  Shapiro-Wilk test p-value: %.6f\n', p_sw);
if p_sw < 0.05
    fprintf(fid, '  Residuals are NOT normally distributed\n\n');
else
   fprintf(fid, '  Residuals are normally distributed\n\n');
end

fprintf(fid, '\n========================================================\n');
fprintf(fid, '* p < 0.05; ** p < 0.01; *** p < 0.001\n');
fprintf(fid, '========================================================\n');

fclose(fid);

fprintf('Results saved to "MBP_CARS_Correlation_Results.txt"\n\n');

%% Save results to CSV
fprintf('Saving summary statistics to CSV...\n');

% Create summary table
summary_table = table(...
    {'Pearson r'; 'Pearson p-value'; 'Pearson R²'; ...
     'Spearman ρ'; 'Spearman p-value'; ...
     'Slope'; 'Slope SE'; 'Slope p-value'; ...
     'Intercept'; 'Intercept SE'; 'Intercept p-value'; ...
     'Model R²'; 'Adjusted R²'; 'RMSE'; ...
     'Sample size'; 'CARS mean'; 'CARS SD'; 'MBP mean'; 'MBP SD'}, ...
    [r_pearson; p_pearson; r_pearson^2; ...
     r_spearman; p_spearman; ...
     mdl.Coefficients.Estimate(2); mdl.Coefficients.SE(2); mdl.Coefficients.pValue(2); ...
     mdl.Coefficients.Estimate(1); mdl.Coefficients.SE(1); mdl.Coefficients.pValue(1); ...
     mdl.Rsquared.Ordinary; mdl.Rsquared.Adjusted; mdl.RMSE; ...
     length(x_clean); mean(x_clean); std(x_clean); mean(y_clean); std(y_clean)], ...
    'VariableNames', {'Statistic', 'Value'});

writetable(summary_table, 'MBP_CARS_Correlation_Summary.csv');
fprintf('Summary saved to "MBP_CARS_Correlation_Summary.csv"\n\n');

%% Additional analysis: Bland-Altman plot
fprintf('Creating Bland-Altman plot...\n');

figure('Position', [200, 200, 800, 600]);

% Calculate mean and difference
mean_vals = (x_clean + y_clean) / 2;
diff_vals = y_clean - x_clean;

% Calculate statistics
mean_diff = mean(diff_vals);
sd_diff = std(diff_vals);
upper_loa = mean_diff + 1.96 * sd_diff;  % Upper limit of agreement
lower_loa = mean_diff - 1.96 * sd_diff;  % Lower limit of agreement

% Plot
scatter(mean_vals, diff_vals, 50, [0.3, 0.6, 0.9], 'filled', 'MarkerFaceAlpha', 0.6);
hold on;

% Add mean difference line
yline(mean_diff, 'r-', 'LineWidth', 2, 'Label', sprintf('Mean: %.2f', mean_diff));

% Add limits of agreement
yline(upper_loa, 'r--', 'LineWidth', 1.5, 'Label', sprintf('+1.96 SD: %.2f', upper_loa));
yline(lower_loa, 'r--', 'LineWidth', 1.5, 'Label', sprintf('-1.96 SD: %.2f', lower_loa));

% Add zero line
yline(0, 'k:', 'LineWidth', 1, 'Label', 'Zero');

hold off;

% Format plot
xlabel('Mean of MBP and CARS', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Difference (MBP - CARS)', 'FontSize', 12, 'FontWeight', 'bold');
title('Bland-Altman Plot: Agreement between MBP and CARS', 'FontSize', 14, 'FontWeight', 'bold');
grid on;
set(gca, 'GridAlpha', 0.3);

% Add statistics text
text_x = min(mean_vals) + 0.05 * range(mean_vals);
text_y = max(diff_vals) - 0.05 * range(diff_vals);
ba_text = sprintf('Mean difference: %.3f\nSD: %.3f\n95%% LoA: [%.3f, %.3f]', ...
    mean_diff, sd_diff, lower_loa, upper_loa);
text(text_x, text_y, ba_text, 'FontSize', 11, 'BackgroundColor', 'white', ...
     'EdgeColor', 'black', 'VerticalAlignment', 'top');

% Save figure
saveas(gcf, 'MBP_CARS_BlandAltman.png');
saveas(gcf, 'MBP_CARS_BlandAltman.fig');

fprintf('Bland-Altman plot saved as "MBP_CARS_BlandAltman.png"\n\n');

%% Calculate concordance correlation coefficient (CCC)
fprintf('========================================\n');
fprintf('CONCORDANCE CORRELATION COEFFICIENT\n');
fprintf('========================================\n\n');

% CCC calculation
mean_x = mean(x_clean);
mean_y = mean(y_clean);
var_x = var(x_clean);
var_y = var(y_clean);
sd_x = std(x_clean);
sd_y = std(y_clean);

% Lin's concordance correlation coefficient
ccc = (2 * r_pearson * sd_x * sd_y) / (var_x + var_y + (mean_x - mean_y)^2);

fprintf('Concordance Correlation Coefficient (CCC): %.4f\n', ccc);

% Interpret CCC
if ccc > 0.99
    fprintf('Interpretation: Almost perfect agreement\n\n');
elseif ccc > 0.95
    fprintf('Interpretation: Substantial agreement\n\n');
elseif ccc > 0.90
    fprintf('Interpretation: Moderate agreement\n\n');
else
    fprintf('Interpretation: Poor agreement\n\n');
end

%% Final Summary
fprintf('========================================\n');
fprintf('=== ANALYSIS COMPLETE ===\n');
fprintf('========================================\n\n');

fprintf('Files generated:\n');
fprintf('  1. MBP_CARS_Correlation.png - Scatter plot with regression line\n');
fprintf('  2. MBP_CARS_Correlation.fig - MATLAB figure file\n');
fprintf('  3. MBP_CARS_Residual_Diagnostics.png - Residual diagnostic plots\n');
fprintf('  4. MBP_CARS_Residual_Diagnostics.fig - MATLAB figure file\n');
fprintf('  5. MBP_CARS_BlandAltman.png - Bland-Altman plot\n');
fprintf('  6. MBP_CARS_BlandAltman.fig - MATLAB figure file\n');
fprintf('  7. MBP_CARS_Correlation_Results.txt - Detailed text results\n');
fprintf('  8. MBP_CARS_Correlation_Summary.csv - Summary statistics\n\n');

fprintf('Summary of Key Results:\n');
fprintf('----------------------\n');
fprintf('Sample size: %d\n', length(x_clean));
fprintf('Pearson r: %.4f (p = %.6e)\n', r_pearson, p_pearson);
fprintf('Spearman ρ: %.4f (p = %.6e)\n', r_spearman, p_spearman);
fprintf('R²: %.4f\n', r_pearson^2);
fprintf('Regression equation: y = %.4f + %.4f * x\n', mdl.Coefficients.Estimate(1), mdl.Coefficients.Estimate(2));
fprintf('Concordance Correlation Coefficient: %.4f\n', ccc);
fprintf('Bland-Altman mean difference: %.4f\n', mean_diff);
fprintf('Bland-Altman 95%% limits of agreement: [%.4f, %.4f]\n\n', lower_loa, upper_loa);

% Interpretation
fprintf('Interpretation:\n');
fprintf('--------------\n');
if abs(r_pearson) > 0.7 && p_pearson < 0.05
    fprintf('Strong and significant correlation between MBP and CARS measurements.\n');
elseif abs(r_pearson) > 0.5 && p_pearson < 0.05
    fprintf('Moderate and significant correlation between MBP and CARS measurements.\n');
elseif abs(r_pearson) > 0.3 && p_pearson < 0.05
    fprintf('Weak but significant correlation between MBP and CARS measurements.\n');
else
    fprintf('No significant correlation between MBP and CARS measurements.\n');
end

if ccc > 0.90
    fprintf('Good agreement between methods (CCC > 0.90).\n');
else
    fprintf('Limited agreement between methods (CCC ≤ 0.90).\n');
end

fprintf('\n========================================\n');
fprintf('All analyses completed successfully!\n');
fprintf('========================================\n\n');

%% Save workspace
fprintf('Saving workspace to Correlation_Analysis_Workspace.mat...\n');
save('Correlation_Analysis_Workspace.mat');
fprintf('Workspace saved.\n\n');

fprintf('=== END OF SCRIPT ===\n');