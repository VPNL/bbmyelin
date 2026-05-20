% Olig2 density_mm2 Analysis - Layer and Age_group
% Linear Mixed-Effects Model: Olig2_density_mm2 ~ Layer*Age_group + (1|Slide_number)
% Author: [Your Name]
% Date: [Current Date]
% MATLAB Version: 2024b

%% Clear workspace
clear; clc; close all;

%% Load data
data = readtable('FigS8a.csv');

%% Display data summary
fprintf('========================================\n');
fprintf('OLIG2 DENSITY ANALYSIS\n');
fprintf('Layer × Age_group Interaction\n');
fprintf('========================================\n\n');

fprintf('Dataset Summary:\n');
fprintf('================\n');
fprintf('Total observations: %d\n', height(data));
fprintf('Number of layers: %d\n', length(unique(data.Layer)));
fprintf('Number of unique slides: %d\n', length(unique(data.Slide_number)));
fprintf('Age range: %.1f - %.1f months\n\n', min(data.Age), max(data.Age));

fprintf('Observations per layer:\n');
disp(tabulate(data.Layer));

fprintf('Observations per age group:\n');
disp(tabulate(data.Age_group));

%% Prepare categorical variables
data.Layer = categorical(data.Layer);
data.Slide_number = categorical(data.Slide_number);
data.Age_group = categorical(data.Age_group);

%% Fit Linear Mixed-Effects Model
fprintf('\nFitting linear mixed-effects model...\n');
fprintf('Model formula: Olig2_density_mm2 ~ Layer*Age_group + (1|Slide_number)\n');
fprintf('Using REML estimation\n\n');

lme = fitlme(data, 'Olig2_density_mm2 ~ Layer * Age_group + (1|Slide_number)', 'FitMethod', 'REML');

fprintf('Model Results:\n');
fprintf('==============\n\n');
disp(lme);

fprintf('\n=== Fixed Effects ===\n');
disp(lme.Coefficients);

fprintf('\n=== Random Effects ===\n');
[psi, mse] = covarianceParameters(lme);
slide_SD = sqrt(psi{1});
residual_SD = sqrt(mse);
ICC = psi{1} / (psi{1} + mse);

fprintf('Slide_number random intercept SD: %.4f\n', slide_SD);
fprintf('Residual SD: %.4f\n', residual_SD);
fprintf('Intraclass Correlation (ICC): %.4f\n', ICC);

fprintf('\n=== Model Fit Statistics ===\n');
fprintf('AIC: %.2f\n', lme.ModelCriterion.AIC);
fprintf('BIC: %.2f\n', lme.ModelCriterion.BIC);
fprintf('R-squared (ordinary): %.4f\n', lme.Rsquared.Ordinary);
fprintf('R-squared (adjusted): %.4f\n', lme.Rsquared.Adjusted);

fprintf('\n=== ANOVA for Fixed Effects ===\n');
anova_results = anova(lme);
disp(anova_results);

%% Get unique categories
layers = categories(data.Layer);
age_groups = categories(data.Age_group);

% Define layer colors
layer_colors = containers.Map({'Deep', 'Middle', 'Superficial'}, ...
                              {[0.3, 0.3, 0.3], [0.5, 0.5, 0.5], [0.7, 0.7, 0.7]});

%% PLOT: Layers by Age Group
fprintf('\nGenerating plot: Layers across age groups...\n');

figure('Position', [100, 100, 1000, 600]);

n_groups = length(age_groups);

for i = 1:length(layers)
    layer_name = char(layers{i});
    layer_data = data(data.Layer == layers{i}, :);
    
    means = zeros(n_groups, 1);
    sems = zeros(n_groups, 1);
    x_positions = 1:n_groups;
    
    for j = 1:n_groups
        group_data = layer_data(layer_data.Age_group == age_groups{j}, :);
        if ~isempty(group_data)
            means(j) = mean(group_data.Olig2_density_mm2);
            sems(j) = std(group_data.Olig2_density_mm2) / sqrt(height(group_data));
        else
            means(j) = NaN;
            sems(j) = NaN;
        end
    end
    
    errorbar(x_positions, means, sems, 'o', ...
             'Color', layer_colors(layer_name), ...
             'MarkerFaceColor', layer_colors(layer_name), ...
             'MarkerSize', 10, ...
             'LineWidth', 2, ...
             'CapSize', 8, ...
             'DisplayName', layer_name);
    hold on;
end

set(gca, 'XTick', 1:n_groups, 'XTickLabel', age_groups);
xtickangle(45);
xlabel('Age Group', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Olig2 density (cells/mm^2)', 'FontSize', 14, 'FontWeight', 'bold');
title('Olig2 Density Across Layers and Age Groups', 'FontSize', 16, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 12);
grid on;
box on;
set(gca, 'FontSize', 12);

filename = 'Olig2_density_by_layer_age.png';
saveas(gcf, filename);
fprintf('Plot saved as "%s"\n', filename);

%% Generate Supplemental Table
fprintf('\n========================================\n');
fprintf('GENERATING SUPPLEMENTAL TABLE\n');
fprintf('========================================\n\n');

% Build the Values string
values_str = '';
n_str = '';

% Create age labels dynamically
age_labels_clean = cell(size(age_groups));
for k = 1:length(age_groups)
    temp_label = char(age_groups{k});
    age_labels_clean{k} = temp_label(3:end);
end

fprintf('Detected age groups:\n');
for k = 1:length(age_groups)
    fprintf('  %s -> %s\n', char(age_groups{k}), age_labels_clean{k});
end
fprintf('\n');

for i = 1:length(age_groups)
    ag = age_groups{i};
    age_label = age_labels_clean{i};
    values_str = [values_str, sprintf('\n%s:\n', age_label)];
    
    for j = 1:length(layers)
        layer = char(layers{j});
        subset = data(data.Age_group == ag & data.Layer == layers{j}, :);
        
        if ~isempty(subset)
            mean_val = mean(subset.Olig2_density_mm2);
            sem_val = std(subset.Olig2_density_mm2) / sqrt(height(subset));
            values_str = [values_str, sprintf('  %s: %.2f±%.2f\n', layer, mean_val, sem_val)];
        end
    end
end

% Count total sections per age group
for i = 1:length(age_groups)
    ag = age_groups{i};
    age_label = age_labels_clean{i};
    n_sections = sum(data.Age_group == ag);
    n_str = [n_str, sprintf('%s: %d sections\n', age_label, n_sections)];
end

% Build statistical test string
stat_test_str = sprintf('Dataset (0-24 months, n=%d sections):\n', height(data));
stat_test_str = [stat_test_str, sprintf(['Restricted Maximum Likelihood model (REML) to predict Olig2 density with ', ...
    'categorical Age_group and Layer (Deep vs. Middle vs. Superficial), ', ...
    'with interaction, and with random variable of section.\n\n'])];

% Add ANOVA results
age_group_idx = find(strcmp(anova_results.Term, 'Age_group'));
layer_idx = find(strcmp(anova_results.Term, 'Layer'));
layer_age_group_idx = find(strcmp(anova_results.Term, 'Layer:Age_group') | strcmp(anova_results.Term, 'Age_group:Layer'));

stat_test_str = [stat_test_str, sprintf('Main effect of Age_group (categorical): F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(age_group_idx), anova_results.DF2(age_group_idx), ...
    anova_results.FStat(age_group_idx), anova_results.pValue(age_group_idx))];

stat_test_str = [stat_test_str, sprintf('Main effect of Layer: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(layer_idx), anova_results.DF2(layer_idx), ...
    anova_results.FStat(layer_idx), anova_results.pValue(layer_idx))];

stat_test_str = [stat_test_str, sprintf('Layer × Age_group interaction: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(layer_age_group_idx), anova_results.DF2(layer_age_group_idx), ...
    anova_results.FStat(layer_age_group_idx), anova_results.pValue(layer_age_group_idx))];

stat_test_str = [stat_test_str, sprintf('R²=%.2f\n', lme.Rsquared.Ordinary)];

%% Perform post-hoc pairwise comparisons based on significant effects
fprintf('\n========================================\n');
fprintf('POST-HOC PAIRWISE COMPARISONS\n');
fprintf('========================================\n');
fprintf('Only performing post-hoc tests for significant main effects and interactions (p < 0.05)\n\n');

posthoc_results = {};

% Check which effects are significant
layer_significant = anova_results.pValue(layer_idx) < 0.05;
age_group_significant = anova_results.pValue(age_group_idx) < 0.05;
layer_age_group_significant = anova_results.pValue(layer_age_group_idx) < 0.05;

fprintf('Significant effects:\n');
fprintf('  Main effect of Layer: %s (p=%.4f)\n', ...
    ternary(layer_significant, 'YES', 'NO'), anova_results.pValue(layer_idx));
fprintf('  Main effect of Age_group: %s (p=%.4f)\n', ...
    ternary(age_group_significant, 'YES', 'NO'), anova_results.pValue(age_group_idx));
fprintf('  Layer × Age_group interaction: %s (p=%.4f)\n\n', ...
    ternary(layer_age_group_significant, 'YES', 'NO'), anova_results.pValue(layer_age_group_idx));

% Helper function for ternary operator
function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end

%% POST-HOC TEST 1: Layer main effect (if significant)
if layer_significant
    fprintf('\n--- POST-HOC: Layer Comparisons (Main Effect) ---\n');
    fprintf('Comparing layers collapsed across age groups\n\n');
    
    % Create all pairwise layer combinations
    layer_pairs = {};
    for i = 1:length(layers)-1
        for j = i+1:length(layers)
            layer_pairs{end+1} = {char(layers{i}), char(layers{j})};
        end
    end
    
    for j = 1:length(layer_pairs)
        layer1 = layer_pairs{j}{1};
        layer2 = layer_pairs{j}{2};
        
        data1 = data(data.Layer == layer1, :);
        data2 = data(data.Layer == layer2, :);
        
        if ~isempty(data1) && ~isempty(data2)
            [h, p] = ttest2(data1.Olig2_density_mm2, data2.Olig2_density_mm2);
            
            mean1 = mean(data1.Olig2_density_mm2);
            mean2 = mean(data2.Olig2_density_mm2);
            
            comparison = sprintf('%s vs. %s', layer1, layer2);
            
            fprintf('  %s: ', comparison);
            fprintf('%.2f vs. %.2f, p=%.6f', mean1, mean2, p);
            
            if p < 0.05
                fprintf(' *');
                if p < 0.001
                    posthoc_results{end+1} = sprintf('%s: p<0.001', comparison);
                else
                    posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                end
            end
            fprintf('\n');
        end
    end
else
    fprintf('\n--- POST-HOC: Layer Comparisons ---\n');
    fprintf('Skipped (main effect not significant, p=%.4f)\n', anova_results.pValue(layer_idx));
end

%% POST-HOC TEST 2: Age_group main effect (if significant)
if age_group_significant
    fprintf('\n--- POST-HOC: Age_group Comparisons (Main Effect) ---\n');
    fprintf('Comparing age groups collapsed across layers\n\n');
    
    % Create all pairwise age group combinations
    age_group_pairs = {};
    for i = 1:length(age_groups)-1
        for j = i+1:length(age_groups)
            age_group_pairs{end+1} = {char(age_groups{i}), char(age_groups{j})};
        end
    end
    
    for j = 1:length(age_group_pairs)
        age1 = age_group_pairs{j}{1};
        age2 = age_group_pairs{j}{2};
        
        data1 = data(data.Age_group == age1, :);
        data2 = data(data.Age_group == age2, :);
        
        if ~isempty(data1) && ~isempty(data2)
            [h, p] = ttest2(data1.Olig2_density_mm2, data2.Olig2_density_mm2);
            
            mean1 = mean(data1.Olig2_density_mm2);
            mean2 = mean(data2.Olig2_density_mm2);
            
            % Get clean labels
            age1_clean = age1(3:end);
            age2_clean = age2(3:end);
            
            comparison = sprintf('%s vs. %s', age1_clean, age2_clean);
            
            fprintf('  %s: ', comparison);
            fprintf('%.2f vs. %.2f, p=%.6f', mean1, mean2, p);
            
            if p < 0.05
                fprintf(' *');
                if p < 0.001
                    posthoc_results{end+1} = sprintf('%s: p<0.001', comparison);
                else
                    posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                end
            end
            fprintf('\n');
        end
    end
else
    fprintf('\n--- POST-HOC: Age_group Comparisons ---\n');
    fprintf('Skipped (main effect not significant, p=%.4f)\n', anova_results.pValue(age_group_idx));
end

%% POST-HOC TEST 3: Layer × Age_group interaction (if significant)
if layer_age_group_significant
    fprintf('\n--- POST-HOC: Layer × Age_group Interaction ---\n');
    fprintf('Comparing layers within each age group\n\n');
    
    for i = 1:length(age_groups)
        ag = age_groups{i};
        age_label = age_labels_clean{i};
        
        fprintf('\n%s:\n', age_label);
        
        age_subset = data(data.Age_group == ag, :);
        
        if isempty(age_subset)
            fprintf('  No data\n');
            continue;
        end
        
        % Create all pairwise layer combinations
        layer_pairs = {};
        for ii = 1:length(layers)-1
            for jj = ii+1:length(layers)
                layer_pairs{end+1} = {char(layers{ii}), char(layers{jj})};
            end
        end
        
        for j = 1:length(layer_pairs)
            layer1 = layer_pairs{j}{1};
            layer2 = layer_pairs{j}{2};
            
            data1 = age_subset(age_subset.Layer == layer1, :);
            data2 = age_subset(age_subset.Layer == layer2, :);
            
            if ~isempty(data1) && ~isempty(data2)
                [h, p] = ttest2(data1.Olig2_density_mm2, data2.Olig2_density_mm2);
                
                mean1 = mean(data1.Olig2_density_mm2);
                mean2 = mean(data2.Olig2_density_mm2);
                
                comparison = sprintf('%s, %s vs. %s, %s', layer1, age_label, layer2, age_label);
                
                fprintf('  %s vs. %s: ', layer1, layer2);
                fprintf('%.2f vs. %.2f, p=%.6f', mean1, mean2, p);
                
                if p < 0.05
                    fprintf(' *');
                    if p < 0.001
                        posthoc_results{end+1} = sprintf('%s: p<0.001', comparison);
                    else
                        posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                    end
                end
                fprintf('\n');
            end
        end
    end
else
    fprintf('\n--- POST-HOC: Layer × Age_group Interaction ---\n');
    fprintf('Skipped (interaction not significant, p=%.4f)\n', anova_results.pValue(layer_age_group_idx));
end

% Build significance string
significance_str = 'Post-hoc pairwise comparisons using Student''s t-test:\n';
significance_str = [significance_str, 'Only performed for significant main effects and interactions (p < 0.05)\n\n'];

if ~isempty(posthoc_results)
    for i = 1:length(posthoc_results)
        significance_str = [significance_str, posthoc_results{i}, '\n'];
    end
    significance_str = [significance_str, '\nAll other comparisons p>0.05'];
else
    significance_str = [significance_str, 'No significant pairwise comparisons found'];
end

%% Save supplemental table
supp_table = table(...
    {'Fig. 2e'}, ...
    {'Olig2 density (cells/mm²) of individual sections across layers and age groups'}, ...
    {values_str}, ...
    {n_str}, ...
    {stat_test_str}, ...
    {significance_str}, ...
    'VariableNames', {'Supplemental_Fig', 'Measure', 'Values', 'N', 'Statistical_test', 'Significance'});

% Save to CSV
writetable(supp_table, 'Olig2_Layer_Age_Supplemental_Table.csv');
fprintf('\nSupplemental table saved to "Olig2_Layer_Age_Supplemental_Table.csv"\n');

% Also save a more readable text version
fid_supp = fopen('Olig2_Layer_Age_Supplemental_Table.txt', 'w');
fprintf(fid_supp, '========================================================\n');
fprintf(fid_supp, 'SUPPLEMENTAL TABLE - Olig2 Density Analysis\n');
fprintf(fid_supp, 'Layer × Age_group Interaction\n');
fprintf(fid_supp, '========================================================\n\n');

fprintf(fid_supp, 'Figure: Fig. 2e\n\n');

fprintf(fid_supp, 'Measure:\n');
fprintf(fid_supp, 'Olig2 density (cells/mm²) of individual sections across layers and age groups\n\n');

fprintf(fid_supp, 'Values (Mean±SEM):\n');
fprintf(fid_supp, '------------------\n');
fprintf(fid_supp, values_str);

fprintf(fid_supp, '\n\nSample Sizes:\n');
fprintf(fid_supp, '-------------\n');
fprintf(fid_supp, n_str);

fprintf(fid_supp, '\n\nStatistical Tests:\n');
fprintf(fid_supp, '------------------\n');
fprintf(fid_supp, stat_test_str);

fprintf(fid_supp, '\n\n\nPost-hoc Comparisons:\n');
fprintf(fid_supp, '---------------------\n');
fprintf(fid_supp, significance_str);

fprintf(fid_supp, '\n\n========================================================\n');
fclose(fid_supp);

fprintf('Readable supplemental table saved to "Olig2_Layer_Age_Supplemental_Table.txt"\n');

% Display preview of statistics
fprintf('\n========================================================\n');
fprintf('SUPPLEMENTAL TABLE PREVIEW - Statistical Tests\n');
fprintf('========================================================\n\n');
fprintf(stat_test_str);

fprintf('\n========================================\n');
fprintf('SUPPLEMENTAL TABLE PREVIEW - Post-hoc Comparisons\n');
fprintf('========================================\n\n');
fprintf(significance_str);

fprintf('\n\n=== All outputs complete ===\n');
fprintf('Files generated:\n');
fprintf('  1. Olig2_density_by_layer_age.png\n');
fprintf('  2. Olig2_Layer_Age_Supplemental_Table.csv\n');
fprintf('  3. Olig2_Layer_Age_Supplemental_Table.txt\n\n');

fprintf('=== ANALYSIS COMPLETE ===\n\n');