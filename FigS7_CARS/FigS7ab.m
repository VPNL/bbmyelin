% Coverage Percent Analysis
% Linear Mixed-Effects Model: Coverage_percent ~ Measure*Cortex_v_WM + (1|Image_ID)
% Linear Mixed-Effects Model: Coverage_percent ~ Measure*Layer + (1|Image_ID)
% Author: [Your Name]
% Date: [Current Date]
% MATLAB Version: 2024b

%% Clear workspace
clear; clc; close all;

%% Load data
data_coverage = readtable('FigS7ab.csv');  % Replace with your actual filename

%% Display data summary
fprintf('Dataset Summary:\n');
fprintf('================\n');
fprintf('Total observations: %d\n', height(data_coverage));
fprintf('Number of Measures: %d\n', length(unique(data_coverage.Measure)));
fprintf('Number of Cortex_v_WM categories: %d\n', length(unique(data_coverage.Cortex_v_WM)));
fprintf('Number of Layers: %d\n', length(unique(data_coverage.Layer)));
fprintf('Number of unique slides: %d\n', length(unique(data_coverage.Image_ID)));

fprintf('\nMeasures:\n');
disp(unique(data_coverage.Measure));

fprintf('Cortex_v_WM categories:\n');
disp(unique(data_coverage.Cortex_v_WM));

fprintf('Layers:\n');
disp(unique(data_coverage.Layer));

fprintf('\nObservations per Measure:\n');
disp(tabulate(data_coverage.Measure));

fprintf('\nObservations per Cortex_v_WM:\n');
disp(tabulate(data_coverage.Cortex_v_WM));

fprintf('\nObservations per Layer:\n');
disp(tabulate(data_coverage.Layer));

%% Prepare variables
data_coverage.Measure = categorical(data_coverage.Measure);
data_coverage.Cortex_v_WM = categorical(data_coverage.Cortex_v_WM);
data_coverage.Layer = categorical(data_coverage.Layer);
data_coverage.Image_ID = categorical(data_coverage.Image_ID);

%% ========================================================================
%% ANALYSIS 1: Coverage_percent by Measure and Cortex_v_WM
%% ========================================================================

fprintf('\n\n========================================\n');
fprintf('ANALYSIS 1: CORTEX vs WHITE MATTER\n');
fprintf('========================================\n\n');

%% Fit Linear Mixed-Effects Model - Cortex_v_WM
fprintf('Fitting linear mixed-effects model...\n');
fprintf('Model formula: Coverage_percent ~ Measure*Cortex_v_WM + (1|Image_ID)\n');
fprintf('Using REML estimation\n\n');

lme_cortex = fitlme(data_coverage, 'Coverage_percent ~ Measure * Cortex_v_WM + (1|Image_ID)', 'FitMethod', 'REML');

fprintf('Model Results:\n');
fprintf('==============\n\n');
disp(lme_cortex);

fprintf('\n=== Fixed Effects ===\n');
disp(lme_cortex.Coefficients);

fprintf('\n=== Random Effects ===\n');
[psi_cortex, mse_cortex] = covarianceParameters(lme_cortex);
slide_SD_cortex = sqrt(psi_cortex{1});
residual_SD_cortex = sqrt(mse_cortex);
ICC_cortex = psi_cortex{1} / (psi_cortex{1} + mse_cortex);

fprintf('Slide random intercept SD: %.4f\n', slide_SD_cortex);
fprintf('Residual SD: %.4f\n', residual_SD_cortex);
fprintf('Intraclass Correlation (ICC): %.4f\n', ICC_cortex);

fprintf('\n=== Model Fit Statistics ===\n');
fprintf('AIC: %.2f\n', lme_cortex.ModelCriterion.AIC);
fprintf('BIC: %.2f\n', lme_cortex.ModelCriterion.BIC);
fprintf('R-squared (ordinary): %.4f\n', lme_cortex.Rsquared.Ordinary);
fprintf('R-squared (adjusted): %.4f\n', lme_cortex.Rsquared.Adjusted);

fprintf('\n=== ANOVA for Fixed Effects ===\n');
anova_results_cortex = anova(lme_cortex);
disp(anova_results_cortex);

%% Get unique values for plotting
unique_measures = unique(data_coverage.Measure);
unique_cortex = unique(data_coverage.Cortex_v_WM);

%% Calculate means and SEMs for Cortex vs WM
means_cortex = nan(length(unique_measures), length(unique_cortex));
sems_cortex = nan(length(unique_measures), length(unique_cortex));

for i = 1:length(unique_measures)
    for j = 1:length(unique_cortex)
        subset = data_coverage(data_coverage.Measure == unique_measures(i) & ...
                              data_coverage.Cortex_v_WM == unique_cortex(j), :);
        if height(subset) > 0
            means_cortex(i, j) = mean(subset.Coverage_percent);
            sems_cortex(i, j) = std(subset.Coverage_percent) / sqrt(height(subset));
        end
    end
end

%% Create Bar Plot - Coverage_percent by Measure and Cortex_v_WM
fprintf('\nCreating bar plot for Cortex vs WM analysis...\n');

% Create figure
figure('Position', [100, 100, 800, 600]);

% Define colors for Cortex vs WM
cortex_colors = [0.3, 0.6, 0.9; 0.9, 0.5, 0.2]; % Blue for Cortex, Orange for WM

% Create grouped bar plot
x_pos = 1:length(unique_measures);
bar_width = 0.35;

hold on;
for j = 1:length(unique_cortex)
    offset = (j - 1.5) * bar_width;
    b = bar(x_pos + offset, means_cortex(:, j), bar_width, 'FaceColor', cortex_colors(j, :));
    
    % Add error bars
    errorbar(x_pos + offset, means_cortex(:, j), sems_cortex(:, j), ...
             'k', 'LineStyle', 'none', 'LineWidth', 1.5);
end
hold off;

% Format plot
xlabel('Measure', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Coverage Percent (%)', 'FontSize', 12, 'FontWeight', 'bold');
title('Coverage Percent by Measure and Cortex vs White Matter', ...
      'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'XTick', x_pos, 'XTickLabel', cellstr(unique_measures), 'FontSize', 11);
legend(cellstr(unique_cortex), 'Location', 'best', 'FontSize', 10);
grid on;
set(gca, 'GridAlpha', 0.3);

% Save figure
saveas(gcf, 'Coverage_Cortex_vs_WM.png');
saveas(gcf, 'Coverage_Cortex_vs_WM.fig');

%% POST-HOC COMPARISONS - Cortex_v_WM
fprintf('\n========================================\n');
fprintf('POST-HOC COMPARISONS - CORTEX vs WM\n');
fprintf('========================================\n\n');

posthoc_results_cortex = {};

% PART 1: Measure comparisons within each Cortex_v_WM category
fprintf('\nMeasure comparisons within each tissue type:\n');
for i = 1:length(unique_cortex)
    current_cortex = unique_cortex(i);
    
    % Get data for this tissue type
    cortex_subset = data_coverage(data_coverage.Cortex_v_WM == current_cortex, :);
    
    % Compare all measure pairs within this tissue type
    for j = 1:length(unique_measures)-1
        for k = j+1:length(unique_measures)
            measure1 = unique_measures(j);
            measure2 = unique_measures(k);
            
            data1 = cortex_subset(cortex_subset.Measure == measure1, :);
            data2 = cortex_subset(cortex_subset.Measure == measure2, :);
            
            if ~isempty(data1) && ~isempty(data2)
                [h, p] = ttest2(data1.Coverage_percent, data2.Coverage_percent);
                
                comparison = sprintf('%s, %s vs. %s, %s', char(measure1), char(current_cortex), char(measure2), char(current_cortex));
                
                fprintf('  %s: p=%.6f', comparison, p);
                if p < 0.05
                    fprintf(' *');
                    if p < 0.001
                        posthoc_results_cortex{end+1} = sprintf('%s: p<0.001', comparison);
                    elseif p < 0.01
                        posthoc_results_cortex{end+1} = sprintf('%s: p=%.4f', comparison, p);
                    else
                        posthoc_results_cortex{end+1} = sprintf('%s: p=%.4f', comparison, p);
                    end
                end
                fprintf('\n');
            end
        end
    end
end

% PART 2: Cortex_v_WM comparisons within each Measure
fprintf('\nTissue type comparisons within each measure:\n');
for i = 1:length(unique_measures)
    current_measure = unique_measures(i);
    
    % Get data for this measure
    measure_subset = data_coverage(data_coverage.Measure == current_measure, :);
    
    % Compare all cortex pairs within this measure
    for j = 1:length(unique_cortex)-1
        for k = j+1:length(unique_cortex)
            cortex1 = unique_cortex(j);
            cortex2 = unique_cortex(k);
            
            data1 = measure_subset(measure_subset.Cortex_v_WM == cortex1, :);
            data2 = measure_subset(measure_subset.Cortex_v_WM == cortex2, :);
            
            if ~isempty(data1) && ~isempty(data2)
                [h, p] = ttest2(data1.Coverage_percent, data2.Coverage_percent);
                
                comparison = sprintf('%s, %s vs. %s, %s', char(cortex1), char(current_measure), char(cortex2), char(current_measure));
                
                fprintf('  %s: p=%.6f', comparison, p);
                if p < 0.05
                    fprintf(' *');
                    if p < 0.001
                        posthoc_results_cortex{end+1} = sprintf('%s: p<0.001', comparison);
                    elseif p < 0.01
                        posthoc_results_cortex{end+1} = sprintf('%s: p=%.4f', comparison, p);
                    else
                        posthoc_results_cortex{end+1} = sprintf('%s: p=%.4f', comparison, p);
                    end
                end
                fprintf('\n');
            end
        end
    end
end

% PART 3: Overall measure comparisons (collapsed across tissue types)
fprintf('\nOverall measure comparisons (collapsed across tissue types):\n');
for j = 1:length(unique_measures)-1
    for k = j+1:length(unique_measures)
        measure1 = unique_measures(j);
        measure2 = unique_measures(k);
        
        data1 = data_coverage(data_coverage.Measure == measure1, :);
        data2 = data_coverage(data_coverage.Measure == measure2, :);
        
        if ~isempty(data1) && ~isempty(data2)
            [h, p] = ttest2(data1.Coverage_percent, data2.Coverage_percent);
            
            comparison = sprintf('%s vs. %s (all tissue types)', char(measure1), char(measure2));
            
            fprintf('  %s: p=%.6f', comparison, p);
            if p < 0.05
                fprintf(' *');
                if p < 0.001
                    posthoc_results_cortex{end+1} = sprintf('%s: p<0.001', comparison);
                elseif p < 0.01
                    posthoc_results_cortex{end+1} = sprintf('%s: p=%.4f', comparison, p);
                else
                    posthoc_results_cortex{end+1} = sprintf('%s: p=%.4f', comparison, p);
                end
            end
            fprintf('\n');
        end
    end
end

% PART 4: Overall tissue type comparisons (collapsed across measures)
fprintf('\nOverall tissue type comparisons (collapsed across measures):\n');
for j = 1:length(unique_cortex)-1
    for k = j+1:length(unique_cortex)
        cortex1 = unique_cortex(j);
        cortex2 = unique_cortex(k);
        
        data1 = data_coverage(data_coverage.Cortex_v_WM == cortex1, :);
        data2 = data_coverage(data_coverage.Cortex_v_WM == cortex2, :);
        
        if ~isempty(data1) && ~isempty(data2)
            [h, p] = ttest2(data1.Coverage_percent, data2.Coverage_percent);
            
            comparison = sprintf('%s vs. %s (all measures)', char(cortex1), char(cortex2));
            
            fprintf('  %s: p=%.6f', comparison, p);
            if p < 0.05
                fprintf(' *');
                if p < 0.001
                    posthoc_results_cortex{end+1} = sprintf('%s: p<0.001', comparison);
                elseif p < 0.01
                    posthoc_results_cortex{end+1} = sprintf('%s: p=%.4f', comparison, p);
                else
                    posthoc_results_cortex{end+1} = sprintf('%s: p=%.4f', comparison, p);
                end
            end
            fprintf('\n');
        end
    end
end

% Build significance string for Cortex vs WM
significance_str_cortex = 'Post-hoc pairwise comparisons using Student''s t-test:\n\n';
if ~isempty(posthoc_results_cortex)
    for i = 1:length(posthoc_results_cortex)
        significance_str_cortex = [significance_str_cortex, posthoc_results_cortex{i}, '\n'];
    end
    significance_str_cortex = [significance_str_cortex, '\nAll other comparisons p>0.05'];
else
    significance_str_cortex = [significance_str_cortex, 'No significant pairwise comparisons (all p>0.05)'];
end

%% ========================================================================
%% ANALYSIS 2: Coverage_percent by Measure and Layer (Line Graph)
%% ========================================================================

fprintf('\n\n========================================\n');
fprintf('ANALYSIS 2: LAYER ANALYSIS\n');
fprintf('========================================\n\n');

%% Fit Linear Mixed-Effects Model - Layer
fprintf('Fitting linear mixed-effects model...\n');
fprintf('Model formula: Coverage_percent ~ Measure*Layer + (1|Image_ID)\n');
fprintf('Using REML estimation\n\n');

lme_layer = fitlme(data_coverage, 'Coverage_percent ~ Measure * Layer+ (1|Image_ID)', 'FitMethod', 'REML');

fprintf('Model Results:\n');
fprintf('==============\n\n');
disp(lme_layer);

fprintf('\n=== Fixed Effects ===\n');
disp(lme_layer.Coefficients);

fprintf('\n=== Random Effects ===\n');
[psi_layer, mse_layer] = covarianceParameters(lme_layer);
slide_SD_layer = sqrt(psi_layer{1});
residual_SD_layer = sqrt(mse_layer);
ICC_layer = psi_layer{1} / (psi_layer{1} + mse_layer);

fprintf('Slide random intercept SD: %.4f\n', slide_SD_layer);
fprintf('Residual SD: %.4f\n', residual_SD_layer);
fprintf('Intraclass Correlation (ICC): %.4f\n', ICC_layer);

fprintf('\n=== Model Fit Statistics ===\n');
fprintf('AIC: %.2f\n', lme_layer.ModelCriterion.AIC);
fprintf('BIC: %.2f\n', lme_layer.ModelCriterion.BIC);
fprintf('R-squared (ordinary): %.4f\n', lme_layer.Rsquared.Ordinary);
fprintf('R-squared (adjusted): %.4f\n', lme_layer.Rsquared.Adjusted);

fprintf('\n=== ANOVA for Fixed Effects ===\n');
anova_results_layer = anova(lme_layer);
disp(anova_results_layer);

%% Get unique layers
unique_layers = unique(data_coverage.Layer);

%% Calculate means and SEMs for Layer
means_layer = nan(length(unique_measures), length(unique_layers));
sems_layer = nan(length(unique_measures), length(unique_layers));

for i = 1:length(unique_measures)
    for j = 1:length(unique_layers)
        subset = data_coverage(data_coverage.Measure == unique_measures(i) & ...
                              data_coverage.Layer == unique_layers(j), :);
        if height(subset) > 0
            means_layer(i, j) = mean(subset.Coverage_percent);
            sems_layer(i, j) = std(subset.Coverage_percent) / sqrt(height(subset));
        end
    end
end

%% Create Line Graph - Coverage_percent by Measure and Layer
fprintf('\nCreating line graph for Layer analysis...\n');

% Create figure
figure('Position', [100, 100, 900, 600]);

% Define colors for different measures
measure_colors = lines(length(unique_measures));

hold on;
for i = 1:length(unique_measures)
    % Plot line with error bars
    errorbar(1:length(unique_layers), means_layer(i, :), sems_layer(i, :), ...
             '-o', 'Color', measure_colors(i, :), 'LineWidth', 2, ...
             'MarkerSize', 8, 'MarkerFaceColor', measure_colors(i, :), ...
             'DisplayName', char(unique_measures(i)), 'CapSize', 10);
end
hold off;

% Format plot
xlabel('Layer', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Coverage Percent (%) - Mean ± SEM', 'FontSize', 12, 'FontWeight', 'bold');
title('Coverage Percent by Measure and Layer', 'FontSize', 14, 'FontWeight', 'bold');
set(gca, 'XTick', 1:length(unique_layers), 'XTickLabel', cellstr(unique_layers), 'FontSize', 11);
legend('Location', 'best', 'FontSize', 10);
grid on;
set(gca, 'GridAlpha', 0.3);
xlim([0.5, length(unique_layers) + 0.5]);

% Save figure
saveas(gcf, 'Coverage_Layer_LineGraph.png');
saveas(gcf, 'Coverage_Layer_LineGraph.fig');

%% POST-HOC COMPARISONS - Layer
fprintf('\n========================================\n');
fprintf('POST-HOC COMPARISONS - LAYER\n');
fprintf('========================================\n\n');

posthoc_results_layer = {};

% PART 1: Measure comparisons within each Layer
fprintf('\nMeasure comparisons within each layer:\n');
for i = 1:length(unique_layers)
    current_layer = unique_layers(i);
    
    % Get data for this layer
    layer_subset = data_coverage(data_coverage.Layer == current_layer, :);
    
    % Compare all measure pairs within this layer
    for j = 1:length(unique_measures)-1
        for k = j+1:length(unique_measures)
            measure1 = unique_measures(j);
            measure2 = unique_measures(k);
            
            data1 = layer_subset(layer_subset.Measure == measure1, :);
            data2 = layer_subset(layer_subset.Measure == measure2, :);
            
            if ~isempty(data1) && ~isempty(data2)
                [h, p] = ttest2(data1.Coverage_percent, data2.Coverage_percent);
                
                comparison = sprintf('%s, %s vs. %s, %s', char(measure1), char(current_layer), char(measure2), char(current_layer));
                
                fprintf('  %s: p=%.6f', comparison, p);
                if p < 0.05
                    fprintf(' *');
                    if p < 0.001
                        posthoc_results_layer{end+1} = sprintf('%s: p<0.001', comparison);
                    elseif p < 0.01
                        posthoc_results_layer{end+1} = sprintf('%s: p=%.4f', comparison, p);
                    else
                        posthoc_results_layer{end+1} = sprintf('%s: p=%.4f', comparison, p);
                    end
                end
                fprintf('\n');
            end
        end
    end
end

% PART 2: Layer comparisons within each Measure
fprintf('\nLayer comparisons within each measure:\n');
for i = 1:length(unique_measures)
    current_measure = unique_measures(i);
    
    % Get data for this measure
    measure_subset = data_coverage(data_coverage.Measure == current_measure, :);
    
    % Compare all layer pairs within this measure
    for j = 1:length(unique_layers)-1
        for k = j+1:length(unique_layers)
            layer1 = unique_layers(j);
            layer2 = unique_layers(k);
            
            data1 = measure_subset(measure_subset.Layer == layer1, :);
            data2 = measure_subset(measure_subset.Layer == layer2, :);
            
            if ~isempty(data1) && ~isempty(data2)
                [h, p] = ttest2(data1.Coverage_percent, data2.Coverage_percent);
                
                comparison = sprintf('%s, %s vs. %s, %s', char(layer1), char(current_measure), char(layer2), char(current_measure));
                
                fprintf('  %s: p=%.6f', comparison, p);
                if p < 0.05
                    fprintf(' *');
                    if p < 0.001
                        posthoc_results_layer{end+1} = sprintf('%s: p<0.001', comparison);
                    elseif p < 0.01
                        posthoc_results_layer{end+1} = sprintf('%s: p=%.4f', comparison, p);
                    else
                        posthoc_results_layer{end+1} = sprintf('%s: p=%.4f', comparison, p);
                    end
                end
                fprintf('\n');
            end
        end
    end
end

% PART 3: Overall measure comparisons (collapsed across layers)
fprintf('\nOverall measure comparisons (collapsed across layers):\n');
for j = 1:length(unique_measures)-1
    for k = j+1:length(unique_measures)
        measure1 = unique_measures(j);
        measure2 = unique_measures(k);
        
        data1 = data_coverage(data_coverage.Measure == measure1, :);
        data2 = data_coverage(data_coverage.Measure == measure2, :);
        
        if ~isempty(data1) && ~isempty(data2)
            [h, p] = ttest2(data1.Coverage_percent, data2.Coverage_percent);
            
            comparison = sprintf('%s vs. %s (all layers)', char(measure1), char(measure2));
            
            fprintf('  %s: p=%.6f', comparison, p);
            if p < 0.05
                fprintf(' *');
                if p < 0.001
                    posthoc_results_layer{end+1} = sprintf('%s: p<0.001', comparison);
                elseif p < 0.01
                    posthoc_results_layer{end+1} = sprintf('%s: p=%.4f', comparison, p);
                else
                    posthoc_results_layer{end+1} = sprintf('%s: p=%.4f', comparison, p);
                end
            end
            fprintf('\n');
        end
    end
end

% PART 4: Overall layer comparisons (collapsed across measures)
fprintf('\nOverall layer comparisons (collapsed across measures):\n');
for j = 1:length(unique_layers)-1
    for k = j+1:length(unique_layers)
        layer1 = unique_layers(j);
        layer2 = unique_layers(k);
        
        data1 = data_coverage(data_coverage.Layer == layer1, :);
        data2 = data_coverage(data_coverage.Layer == layer2, :);
        
        if ~isempty(data1) && ~isempty(data2)
            [h, p] = ttest2(data1.Coverage_percent, data2.Coverage_percent);
            
            comparison = sprintf('%s vs. %s (all measures)', char(layer1), char(layer2));
            
            fprintf('  %s: p=%.6f', comparison, p);
            if p < 0.05
                fprintf(' *');
                if p < 0.001
                    posthoc_results_layer{end+1} = sprintf('%s: p<0.001', comparison);
                elseif p < 0.01
                    posthoc_results_layer{end+1} = sprintf('%s: p=%.4f', comparison, p);
                else
                    posthoc_results_layer{end+1} = sprintf('%s: p=%.4f', comparison, p);
                end
            end
            fprintf('\n');
        end
    end
end

% Build significance string for Layer
significance_str_layer = 'Post-hoc pairwise comparisons using Student''s t-test:\n\n';
if ~isempty(posthoc_results_layer)
    for i = 1:length(posthoc_results_layer)
        significance_str_layer = [significance_str_layer, posthoc_results_layer{i}, '\n'];
    end
    significance_str_layer = [significance_str_layer, '\nAll other comparisons p>0.05'];
else
    significance_str_layer = [significance_str_layer, 'No significant pairwise comparisons (all p>0.05)'];
end

%% ========================================================================
%% GENERATE SUPPLEMENTAL TABLES
%% ========================================================================

fprintf('\n========================================\n');
fprintf('GENERATING SUPPLEMENTAL TABLES\n');
fprintf('========================================\n\n');

%% Supplemental Table 1: Cortex vs WM Analysis

% Build the Values string (mean ± SEM for each combination)
values_str_cortex = '';
for i = 1:length(unique_cortex)
    values_str_cortex = [values_str_cortex, char(unique_cortex(i)), ':\n'];
    
    for j = 1:length(unique_measures)
        subset = data_coverage(data_coverage.Cortex_v_WM == unique_cortex(i) & data_coverage.Measure == unique_measures(j), :);
        
        if height(subset) > 0
            mean_val = mean(subset.Coverage_percent);
            sem_val = std(subset.Coverage_percent) / sqrt(height(subset));
            values_str_cortex = [values_str_cortex, sprintf('  %s: %.2f±%.2f%%\n', char(unique_measures(j)), mean_val, sem_val)];
        end
    end
    if i < length(unique_cortex)  % Don't add extra newline after last category
        values_str_cortex = [values_str_cortex, '\n'];
    end
end

% Debug: Check the complete string
fprintf('\n=== COMPLETE VALUES STRING (Cortex vs WM) ===\n');
fprintf('%s\n', values_str_cortex);
fprintf('===========================================\n\n');

% Build N string
n_str_cortex = sprintf('Total: %d observations from %d images\n', height(data_coverage), length(unique(data_coverage.Image_ID)));
n_str_cortex = [n_str_cortex, sprintf('Measures: %d (%s)\n', length(unique_measures), strjoin(cellstr(unique_measures), ', '))];
n_str_cortex = [n_str_cortex, sprintf('Tissue types: %d (%s)', length(unique_cortex), strjoin(cellstr(unique_cortex), ', '))];

% Build statistical test string
stat_test_str_cortex = sprintf('COVERAGE PERCENT ANALYSIS - CORTEX vs WHITE MATTER (n=%d observations from %d images):\n', ...
    height(data_coverage), length(unique(data_coverage.Image_ID)));
stat_test_str_cortex = [stat_test_str_cortex, sprintf(['Restricted Maximum Likelihood model (REML) to predict Coverage_percent with ', ...
    'Measure and Cortex_v_WM, with interaction, and with random variable of Image_ID.\n\n'])];

% Add ANOVA results
measure_idx = find(strcmp(anova_results_cortex.Term, 'Measure'));
cortex_idx = find(strcmp(anova_results_cortex.Term, 'Cortex_v_WM'));
interaction_idx = find(strcmp(anova_results_cortex.Term, 'Measure:Cortex_v_WM') | strcmp(anova_results_cortex.Term, 'Cortex_v_WM:Measure'));

stat_test_str_cortex = [stat_test_str_cortex, sprintf('Main effect of Measure: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results_cortex.DF1(measure_idx), anova_results_cortex.DF2(measure_idx), ...
    anova_results_cortex.FStat(measure_idx), anova_results_cortex.pValue(measure_idx))];

stat_test_str_cortex = [stat_test_str_cortex, sprintf('Main effect of Cortex_v_WM: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results_cortex.DF1(cortex_idx), anova_results_cortex.DF2(cortex_idx), ...
    anova_results_cortex.FStat(cortex_idx), anova_results_cortex.pValue(cortex_idx))];

stat_test_str_cortex = [stat_test_str_cortex, sprintf('Interaction effect between Measure and Cortex_v_WM: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results_cortex.DF1(interaction_idx), anova_results_cortex.DF2(interaction_idx), ...
    anova_results_cortex.FStat(interaction_idx), anova_results_cortex.pValue(interaction_idx))];

stat_test_str_cortex = [stat_test_str_cortex, sprintf('R²=%.2f', lme_cortex.Rsquared.Ordinary)];

% Create supplemental table for Cortex vs WM
supp_table_cortex = table(...
    {'Fig. S7a'}, ...
    {'Coverage Percent (%) by Measure andCortex vs White Matter'}, ...
    {values_str_cortex}, ...
    {n_str_cortex}, ...
    {stat_test_str_cortex}, ...
    {significance_str_cortex}, ...
    'VariableNames', {'Supplemental_Fig', 'Measure', 'Values', 'N', 'Statistical_test', 'Significance'});

% Save to CSV
writetable(supp_table_cortex, 'Coverage_Cortex_WM_Supplemental_Table.csv');
fprintf('\nSupplemental table saved to "Coverage_Cortex_WM_Supplemental_Table.csv"\n');

% Save readable text version
fid_supp_cortex = fopen('Coverage_Cortex_WM_Supplemental_Table.txt', 'w');
fprintf(fid_supp_cortex, '========================================================\n');
fprintf(fid_supp_cortex, 'SUPPLEMENTAL TABLE - Coverage Percent: Cortex vs WM\n');
fprintf(fid_supp_cortex, '========================================================\n\n');

fprintf(fid_supp_cortex, 'Figure: Fig. S7a\n\n');

fprintf(fid_supp_cortex, 'Measure:\n');
fprintf(fid_supp_cortex, 'Coverage Percent (%%) by Measure and Cortex vs White Matter\n\n');

fprintf(fid_supp_cortex, 'Values (Mean±SEM):\n');
fprintf(fid_supp_cortex, '------------------\n');
% Fix: Use fprintf with the string, not as a format specifier
fprintf(fid_supp_cortex, '%s', values_str_cortex);

fprintf(fid_supp_cortex, '\n\nSample Sizes:\n');
fprintf(fid_supp_cortex, '-------------\n');
fprintf(fid_supp_cortex, '%s', n_str_cortex);

fprintf(fid_supp_cortex, '\n\n\nStatistical Tests:\n');
fprintf(fid_supp_cortex, '------------------\n');
fprintf(fid_supp_cortex, '%s\n', stat_test_str_cortex);

fprintf(fid_supp_cortex, '\n\n\nPost-hoc Comparisons:\n');
fprintf(fid_supp_cortex, '---------------------\n');
fprintf(fid_supp_cortex, '%s', significance_str_cortex);

fprintf(fid_supp_cortex, '\n\n========================================================\n');
fclose(fid_supp_cortex);

%% Supplemental Table 2: Layer Analysis

% Build the Values string (mean ± SEM for each combination)
values_str_layer = '';
for i = 1:length(unique_layers)
    values_str_layer = [values_str_layer, char(unique_layers(i)), ':\n'];
    
    for j = 1:length(unique_measures)
        subset = data_coverage(data_coverage.Layer == unique_layers(i) & data_coverage.Measure == unique_measures(j), :);
        
        if ~isempty(subset) && height(subset) > 0
            mean_val = mean(subset.Coverage_percent);
            sem_val = std(subset.Coverage_percent) / sqrt(height(subset));
            values_str_layer = [values_str_layer, sprintf('  %s: %.2f±%.2f%%\n', char(unique_measures(j)), mean_val, sem_val)];
        end
    end
    if i < length(unique_layers)  % Don't add extra newline after last layer
        values_str_layer = [values_str_layer, '\n'];
    end
end

% Debug: Check the complete string
fprintf('\n=== COMPLETE VALUES STRING (Layer) ===\n');
fprintf('%s\n', values_str_layer);
fprintf('=======================================\n\n');
% Build N string
n_str_layer = sprintf('Total: %d observations from %d images\n', height(data_coverage), length(unique(data_coverage.Image_ID)));
n_str_layer = [n_str_layer, sprintf('Measures: %d (%s)\n', length(unique_measures), strjoin(cellstr(unique_measures), ', '))];
n_str_layer = [n_str_layer, sprintf('Layers: %d (%s)', length(unique_layers), strjoin(cellstr(unique_layers), ', '))];

% Build statistical test string
stat_test_str_layer = sprintf('COVERAGE PERCENT ANALYSIS - LAYER (n=%d observations from %d images):\n', ...
    height(data_coverage), length(unique(data_coverage.Image_ID)));
stat_test_str_layer = [stat_test_str_layer, sprintf(['Restricted Maximum Likelihood model (REML) to predict Coverage_percent with ', ...
    'Measure and Layer, with interaction, and with random variable of Image_ID.\n\n'])];

% Add ANOVA results
measure_idx_layer = find(strcmp(anova_results_layer.Term, 'Measure'));
layer_idx = find(strcmp(anova_results_layer.Term, 'Layer'));
interaction_idx_layer = find(strcmp(anova_results_layer.Term, 'Measure:Layer') | strcmp(anova_results_layer.Term, 'Layer:Measure'));

stat_test_str_layer = [stat_test_str_layer, sprintf('Main effect of Measure: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results_layer.DF1(measure_idx_layer), anova_results_layer.DF2(measure_idx_layer), ...
    anova_results_layer.FStat(measure_idx_layer), anova_results_layer.pValue(measure_idx_layer))];

stat_test_str_layer = [stat_test_str_layer, sprintf('Main effect of Layer: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results_layer.DF1(layer_idx), anova_results_layer.DF2(layer_idx), ...
    anova_results_layer.FStat(layer_idx), anova_results_layer.pValue(layer_idx))];

stat_test_str_layer = [stat_test_str_layer, sprintf('Interaction effect between Measure and Layer: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results_layer.DF1(interaction_idx_layer), anova_results_layer.DF2(interaction_idx_layer), ...
    anova_results_layer.FStat(interaction_idx_layer), anova_results_layer.pValue(interaction_idx_layer))];

stat_test_str_layer = [stat_test_str_layer, sprintf('R²=%.2f', lme_layer.Rsquared.Ordinary)];

% Create supplemental table for Layer
supp_table_layer = table(...
    {'Fig. S7b'}, ...
    {'Coverage Percent (%) by Measure and Layer'}, ...
    {values_str_layer}, ...
    {n_str_layer}, ...
    {stat_test_str_layer}, ...
    {significance_str_layer}, ...
    'VariableNames', {'Supplemental_Fig', 'Measure', 'Values', 'N', 'Statistical_test', 'Significance'});

% Save to CSV
writetable(supp_table_layer, 'Coverage_Layer_Supplemental_Table.csv');
fprintf('Supplemental table saved to "Coverage_Layer_Supplemental_Table.csv"\n');

% Save readable text version
% Save readable text version
fid_supp_layer = fopen('Coverage_Layer_Supplemental_Table.txt', 'w');
fprintf(fid_supp_layer, '========================================================\n');
fprintf(fid_supp_layer, 'SUPPLEMENTAL TABLE - Coverage Percent: Layer Analysis\n');
fprintf(fid_supp_layer, '========================================================\n\n');

fprintf(fid_supp_layer, 'Figure: Fig. S7b\n\n');

fprintf(fid_supp_layer, 'Measure:\n');
fprintf(fid_supp_layer, 'Coverage Percent (%%) by Measure and Layer\n\n');

fprintf(fid_supp_layer, 'Values (Mean±SEM):\n');
fprintf(fid_supp_layer, '------------------\n');
% Fix: Use fprintf with the string, not as a format specifier
fprintf(fid_supp_layer, '%s', values_str_layer);

fprintf(fid_supp_layer, '\n\nSample Sizes:\n');
fprintf(fid_supp_layer, '-------------\n');
fprintf(fid_supp_layer, '%s', n_str_layer);

fprintf(fid_supp_layer, '\n\n\nStatistical Tests:\n');
fprintf(fid_supp_layer, '------------------\n');
fprintf(fid_supp_layer, '%s\n', stat_test_str_layer);

fprintf(fid_supp_layer, '\n\n\nPost-hoc Comparisons:\n');
fprintf(fid_supp_layer, '---------------------\n');
fprintf(fid_supp_layer, '%s', significance_str_layer);

fprintf(fid_supp_layer, '\n\n========================================================\n');
fclose(fid_supp_layer);

%% Display preview of statistics
fprintf('\n========================================================\n');
fprintf('SUPPLEMENTAL TABLE PREVIEW - Statistical Tests\n');
fprintf('========================================================\n\n');

fprintf('--- Cortex vs WM Analysis ---\n');
fprintf('%s\n\n', stat_test_str_cortex);

fprintf('\n========================================\n');
fprintf('SUPPLEMENTAL TABLE PREVIEW - Post-hoc Comparisons (Cortex vs WM)\n');
fprintf('========================================\n\n');
fprintf(significance_str_cortex);

fprintf('\n\n--- Layer Analysis ---\n');
fprintf('%s\n', stat_test_str_layer);

fprintf('\n========================================\n');
fprintf('SUPPLEMENTAL TABLE PREVIEW - Post-hoc Comparisons (Layer)\n');
fprintf('========================================\n\n');
fprintf(significance_str_layer);

%% Final Summary
fprintf('\n\n========================================\n');
fprintf('=== ANALYSIS COMPLETE ===\n');
fprintf('========================================\n\n');

fprintf('Files generated:\n');
fprintf('  1. Coverage_Cortex_vs_WM.png - Bar plot of Coverage by Measure and Cortex vs WM\n');
fprintf('  2. Coverage_Cortex_vs_WM.fig - MATLAB figure file\n');
fprintf('  3. Coverage_Layer_LineGraph.png - Line graph of Coverage by Measure and Layer\n');
fprintf('  4. Coverage_Layer_LineGraph.fig - MATLAB figure file\n');
fprintf('  5. Coverage_Cortex_WM_Supplemental_Table.csv - Cortex vs WM statistical summary (CSV)\n');
fprintf('  6. Coverage_Cortex_WM_Supplemental_Table.txt - Cortex vs WM statistical summary (text)\n');
fprintf('  7. Coverage_Layer_Supplemental_Table.csv - Layer statistical summary (CSV)\n');
fprintf('  8. Coverage_Layer_Supplemental_Table.txt - Layer statistical summary (text)\n\n');

fprintf('Summary Statistics:\n');
fprintf('-------------------\n');
fprintf('Total observations: %d\n', height(data_coverage));
fprintf('Unique images: %d\n', length(unique(data_coverage.Image_ID)));
fprintf('Measures analyzed: %d\n', length(unique_measures));
fprintf('Tissue types (Cortex vs WM): %d\n', length(unique_cortex));
fprintf('Layers analyzed: %d\n\n', length(unique_layers));

fprintf('Model Performance:\n');
fprintf('------------------\n');
fprintf('Cortex vs WM Model:\n');
fprintf('  R² = %.4f\n', lme_cortex.Rsquared.Ordinary);
fprintf('  AIC = %.2f\n', lme_cortex.ModelCriterion.AIC);
fprintf('  BIC = %.2f\n\n', lme_cortex.ModelCriterion.BIC);

fprintf('Layer Model:\n');
fprintf('  R² = %.4f\n', lme_layer.Rsquared.Ordinary);
fprintf('  AIC = %.2f\n', lme_layer.ModelCriterion.AIC);
fprintf('  BIC = %.2f\n\n', lme_layer.ModelCriterion.BIC);

fprintf('Key Findings:\n');
fprintf('-------------\n');

% Cortex vs WM findings
fprintf('\nCortex vs WM Analysis:\n');
if anova_results_cortex.pValue(measure_idx) < 0.05
    fprintf('  ✓ Significant main effect of Measure (p = %.4f)\n', anova_results_cortex.pValue(measure_idx));
else
    fprintf('  ✗ No significant main effect of Measure (p = %.4f)\n', anova_results_cortex.pValue(measure_idx));
end

if anova_results_cortex.pValue(cortex_idx) < 0.05
    fprintf('  ✓ Significant main effect of Cortex vs WM (p = %.4f)\n', anova_results_cortex.pValue(cortex_idx));
else
    fprintf('  ✗ No significant main effect of Cortex vs WM (p = %.4f)\n', anova_results_cortex.pValue(cortex_idx));
end

if anova_results_cortex.pValue(interaction_idx) < 0.05
    fprintf('  ✓ Significant interaction between Measure and Cortex vs WM (p = %.4f)\n', anova_results_cortex.pValue(interaction_idx));
else
    fprintf('  ✗ No significant interaction between Measure and Cortex vs WM (p = %.4f)\n', anova_results_cortex.pValue(interaction_idx));
end

% Layer findings
fprintf('\nLayer Analysis:\n');
if anova_results_layer.pValue(measure_idx_layer) < 0.05
    fprintf('  ✓ Significant main effect of Measure (p = %.4f)\n', anova_results_layer.pValue(measure_idx_layer));
else
    fprintf('  ✗ No significant main effect of Measure (p = %.4f)\n', anova_results_layer.pValue(measure_idx_layer));
end

if anova_results_layer.pValue(layer_idx) < 0.05
    fprintf('  ✓ Significant main effect of Layer (p = %.4f)\n', anova_results_layer.pValue(layer_idx));
else
    fprintf('  ✗ No significant main effect of Layer (p = %.4f)\n', anova_results_layer.pValue(layer_idx));
end

if anova_results_layer.pValue(interaction_idx_layer) < 0.05
    fprintf('  ✓ Significant interaction between Measure and Layer (p = %.4f)\n', anova_results_layer.pValue(interaction_idx_layer));
else
    fprintf('  ✗ No significant interaction between Measure and Layer (p = %.4f)\n', anova_results_layer.pValue(interaction_idx_layer));
end

fprintf('\n========================================\n');
fprintf('All analyses completed successfully!\n');
fprintf('========================================\n\n');

fprintf('=== END OF SCRIPT ===\n');