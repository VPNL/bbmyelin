% MBP Coverage Analysis
% Linear Mixed-Effects Model: MBP_coverage ~ Layer*Age_group + (1|Slide_number)
% Author: [Your Name]
% Date: [Current Date]
% MATLAB Version: 2024b

%% Clear workspace
clear; clc; close all;

%% Load data
data_mbp = readtable('FigS5c.csv');

%% Display data summary
fprintf('Dataset Summary:\n');
fprintf('================\n');
fprintf('Total observations: %d\n', height(data_mbp));
fprintf('Number of layers: %d\n', length(unique(data_mbp.Layer)));
fprintf('Number of unique slides: %d\n', length(unique(data_mbp.Slide_number)));
fprintf('Age range: %.1f - %.1f months\n\n', min(data_mbp.Age), max(data_mbp.Age));

fprintf('Observations per layer:\n');
disp(tabulate(data_mbp.Layer));

fprintf('Observations per age group:\n');
disp(tabulate(data_mbp.Age_group));

%% Prepare variables
data_mbp.Layer = categorical(data_mbp.Layer);
data_mbp.Slide_number = categorical(data_mbp.Slide_number);
data_mbp.Age_group = categorical(data_mbp.Age_group);

%% Fit Linear Mixed-Effects Model - Full Dataset
fprintf('\nFitting linear mixed-effects model (Full Dataset)...\n');
fprintf('Model formula: MBP_coverage ~ Layer*Age_group + (1|Slide_number)\n');
fprintf('Using REML estimation\n\n');

lme = fitlme(data_mbp, 'MBP_coverage ~ Layer * Age_group + (1|Slide_number)', 'FitMethod', 'REML');

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

%% Create visualization - MBP Coverage by Age Group and Layer
fprintf('\nGenerating plot: MBP Coverage by Age Group and Layer...\n');

figure('Position', [100, 100, 1200, 600]);

% Get unique layers and age groups
layers = categories(data_mbp.Layer);
age_groups = categories(data_mbp.Age_group);

% Define purple colors for layers: L4a (light purple) to L4c (dark purple)
% Create color map based on layer names
layer_colors_map = containers.Map();

for i = 1:length(layers)
    layer_name = char(layers{i});
    
    % Check if it's a layer (4a, 4b, 4c) or region (CoS, FG, Calc)
    if contains(layer_name, '4a')
        layer_colors_map(layer_name) = [0.8, 0.6, 1.0];   % Light purple
    elseif contains(layer_name, '4b')
        layer_colors_map(layer_name) = [0.6, 0.4, 0.9];   % Medium purple
    elseif contains(layer_name, '4c')
        layer_colors_map(layer_name) = [0.5, 0.2, 0.7];   % Dark purple
    elseif contains(layer_name, 'CoS')
        layer_colors_map(layer_name) = [0.2, 0.8, 0.4];   % Green
    elseif contains(layer_name, 'FG')
        layer_colors_map(layer_name) = [1.0, 0.4, 0.7];   % Pink
    elseif contains(layer_name, 'Calc')
        layer_colors_map(layer_name) = [0.6, 0.2, 0.8];   % Purple (for Calc if present)
    else
        % Default purple gradient if layer name doesn't match known patterns
        light_purple = [0.8, 0.6, 1.0];
        dark_purple = [0.5, 0.2, 0.7];
        t = (i-1)/max(1, length(layers)-1);
        layer_colors_map(layer_name) = light_purple * (1-t) + dark_purple * t;
    end
end

% Sort age groups for proper ordering on x-axis
age_group_nums = 1:length(age_groups);

% Calculate means and standard errors for each combination
means_matrix = zeros(length(age_groups), length(layers));
se_matrix = zeros(length(age_groups), length(layers));

for i = 1:length(age_groups)
    for j = 1:length(layers)
        subset = data_mbp(data_mbp.Age_group == age_groups{i} & data_mbp.Layer == layers{j}, :);
        if ~isempty(subset)
            means_matrix(i, j) = mean(subset.MBP_coverage, 'omitnan');
            se_matrix(i, j) = std(subset.MBP_coverage, 'omitnan') / sqrt(sum(~isnan(subset.MBP_coverage)));
        else
            means_matrix(i, j) = NaN;
            se_matrix(i, j) = NaN;
        end
    end
end

% Plot with error bars
hold on;
for j = 1:length(layers)
    layer_name = char(layers{j});
    layer_color = layer_colors_map(layer_name);
    
    errorbar(age_group_nums, means_matrix(:, j), se_matrix(:, j), ...
        'o-', 'LineWidth', 2.5, 'MarkerSize', 10, ...
        'MarkerFaceColor', layer_color, ...
        'Color', layer_color, ...
        'DisplayName', layer_name);
end

% Formatting
xlabel('Age Group', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('MBP Coverage (%)', 'FontSize', 14, 'FontWeight', 'bold');
title('MBP Coverage by Age Group and Layer', 'FontSize', 16, 'FontWeight', 'bold');
xticks(age_group_nums);
xticklabels(age_groups);
xtickangle(45);
legend('Location', 'best', 'FontSize', 12);
grid on;
box on;
set(gca, 'FontSize', 12);

saveas(gcf, 'MBP_Coverage_by_Age_Layer.png');
fprintf('Plot saved as "MBP_Coverage_by_Age_Layer.png"\n');

%% Generate Supplemental Table for Publication
fprintf('\n========================================\n');
fprintf('GENERATING SUPPLEMENTAL TABLE\n');
fprintf('========================================\n\n');

% Get actual age groups and layers from data
age_groups = categories(data_mbp.Age_group);
layers_ordered = categories(data_mbp.Layer);

% Build the Values string
values_str = '';
n_str = '';

% Create age labels dynamically (remove prefix letter and underscore)
age_labels_clean = cell(size(age_groups));
for k = 1:length(age_groups)
    % Remove the letter prefix (e.g., 'a_', 'b_', etc.)
    temp_label = char(age_groups{k});
    if length(temp_label) > 2 && temp_label(2) == '_'
        age_labels_clean{k} = temp_label(3:end);  % Skip first 2 characters
    else
        age_labels_clean{k} = temp_label;  % Use as-is if no prefix
    end
end

fprintf('Detected age groups:\n');
for k = 1:length(age_groups)
    fprintf('  %s -> %s\n', char(age_groups{k}), age_labels_clean{k});
end
fprintf('\n');

for i = 1:length(age_groups)
    ag = age_groups{i};
    age_label = age_labels_clean{i};
    values_str = [values_str, age_label, ':\n'];
    
    % Count sections for this age group
    n_sections = sum(data_mbp.Age_group == ag);
    n_str = [n_str, age_label, ': ', num2str(n_sections), ' sections\n'];
    
    for j = 1:length(layers_ordered)
        layer = layers_ordered{j};
        subset = data_mbp(data_mbp.Age_group == ag & data_mbp.Layer == layer, :);
        
        if ~isempty(subset)
            mean_val = mean(subset.MBP_coverage);
            sem_val = std(subset.MBP_coverage) / sqrt(height(subset));
            values_str = [values_str, sprintf('%s: %.2f±%.2f\n', layer, mean_val, sem_val)];
        end
    end
end

% Build statistical test string - FULL DATASET
stat_test_str = sprintf('FULL DATASET (All ages: %.1f-%.1f months, n=%d sections):\n', ...
    min(data_mbp.Age), max(data_mbp.Age), height(data_mbp));
stat_test_str = [stat_test_str, sprintf(['Restricted Maximum Likelihood model (REML) to predict MBP coverage with ', ...
    'categorical Age_group and Layer, ', ...
    'with interaction, and with random variable of section.\n\n'])];

% Add ANOVA results
age_idx = find(strcmp(anova_results.Term, 'Age_group'));
layer_idx = find(strcmp(anova_results.Term, 'Layer'));
interaction_idx = find(strcmp(anova_results.Term, 'Layer:Age_group') | strcmp(anova_results.Term, 'Age_group:Layer'));

stat_test_str = [stat_test_str, sprintf('Main effect of Age_group to predict coverage: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(age_idx), ...
    anova_results.DF2(age_idx), ...
    anova_results.FStat(age_idx), ...
    anova_results.pValue(age_idx))];

stat_test_str = [stat_test_str, sprintf('Main effect of Layer to predict coverage: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(layer_idx), ...
    anova_results.DF2(layer_idx), ...
    anova_results.FStat(layer_idx), ...
    anova_results.pValue(layer_idx))];

stat_test_str = [stat_test_str, sprintf('Interaction effect between Age_group and Layer to predict coverage: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(interaction_idx), ...
    anova_results.DF2(interaction_idx), ...
    anova_results.FStat(interaction_idx), ...
    anova_results.pValue(interaction_idx))];

stat_test_str = [stat_test_str, sprintf('R²=%.2f', lme.Rsquared.Ordinary)];

%% Perform post-hoc pairwise comparisons
fprintf('Performing post-hoc pairwise comparisons...\n');

posthoc_results = {};

% PART 1: Layer comparisons within each age group (for significant interaction)
fprintf('\nLayer comparisons within each age group:\n');
for i = 1:length(age_groups)
    ag = age_groups{i};
    age_label = age_labels_clean{i};
    
    % Get data for this age group
    age_subset = data_mbp(data_mbp.Age_group == ag, :);
    
    % Compare all layer pairs within this age group
    for j = 1:length(layers_ordered)-1
        for k = j+1:length(layers_ordered)
            layer1 = layers_ordered{j};
            layer2 = layers_ordered{k};
            
            data1 = age_subset(age_subset.Layer == layer1, :);
            data2 = age_subset(age_subset.Layer == layer2, :);
            
            if ~isempty(data1) && ~isempty(data2)
                [h, p] = ttest2(data1.MBP_coverage, data2.MBP_coverage);
                
                comparison = sprintf('%s, %s vs. %s, %s', layer1, age_label, layer2, age_label);
                
                fprintf('  %s: p=%.6f', comparison, p);
                if p < 0.05
                    fprintf(' *');
                    if p < 0.001
                        posthoc_results{end+1} = sprintf('%s: p<0.001', comparison);
                    elseif p < 0.01
                        posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                    else
                        posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                    end
                end
                fprintf('\n');
            end
        end
    end
end

% PART 2: Age group comparisons within each layer
fprintf('\nAge group comparisons within each layer:\n');
for r = 1:length(layers_ordered)
    layer = layers_ordered{r};
    
    % Get data for this layer
    layer_subset = data_mbp(data_mbp.Layer == layer, :);
    
    % Compare consecutive age groups
    for i = 1:length(age_groups)-1
        for j = i+1:length(age_groups)
            data1 = layer_subset(layer_subset.Age_group == age_groups{i}, :);
            data2 = layer_subset(layer_subset.Age_group == age_groups{j}, :);
            
            if ~isempty(data1) && ~isempty(data2)
                [h, p] = ttest2(data1.MBP_coverage, data2.MBP_coverage);
                
                comparison = sprintf('%s, %s vs. %s, %s', layer, age_labels_clean{i}, layer, age_labels_clean{j});
                
                fprintf('  %s: p=%.6f', comparison, p);
                if p < 0.05
                    fprintf(' *');
                    if p < 0.001
                        posthoc_results{end+1} = sprintf('%s: p<0.001', comparison);
                    elseif p < 0.01
                        posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                    else
                        posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                    end
                end
                fprintf('\n');end
        end
    end
end

% PART 3: Overall age group comparisons (collapsed across layers)
fprintf('\nOverall age group comparisons (collapsed across layers):\n');
for i = 1:length(age_groups)-1
    for j = i+1:length(age_groups)
        group1_data = data_mbp(data_mbp.Age_group == age_groups{i}, :);
        group2_data = data_mbp(data_mbp.Age_group == age_groups{j}, :);
        
        [h, p] = ttest2(group1_data.MBP_coverage, group2_data.MBP_coverage);
        
        comparison = sprintf('%s vs. %s (all layers)', age_labels_clean{i}, age_labels_clean{j});
        
        fprintf('  %s: p=%.6f', comparison, p);
        if p < 0.05
            fprintf(' *');
            if p < 0.001
                posthoc_results{end+1} = sprintf('%s: p<0.001', comparison);
            elseif p < 0.01
                posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
            else
                posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
            end
        end
        fprintf('\n');
    end
end

% PART 4: Overall layer comparisons (collapsed across age groups)
fprintf('\nOverall layer comparisons (collapsed across age groups):\n');
for j = 1:length(layers_ordered)-1
    for k = j+1:length(layers_ordered)
        layer1 = layers_ordered{j};
        layer2 = layers_ordered{k};
        
        data1 = data_mbp(data_mbp.Layer == layer1, :);
        data2 = data_mbp(data_mbp.Layer == layer2, :);
        
        if ~isempty(data1) && ~isempty(data2)
            [h, p] = ttest2(data1.MBP_coverage, data2.MBP_coverage);
            
            comparison = sprintf('%s vs. %s (all ages)', layer1, layer2);
            
            fprintf('  %s: p=%.6f', comparison, p);
            if p < 0.05
                fprintf(' *');
                if p < 0.001
                    posthoc_results{end+1} = sprintf('%s: p<0.001', comparison);
                elseif p < 0.01
                    posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                else
                    posthoc_results{end+1} = sprintf('%s: p=%.4f', comparison, p);
                end
            end
            fprintf('\n');
        end
    end
end

% Build significance string
significance_str = 'Post-hoc pairwise comparisons using Student''s t-test:\n\n';
if ~isempty(posthoc_results)
    for i = 1:length(posthoc_results)
        significance_str = [significance_str, posthoc_results{i}, '\n'];
    end
    significance_str = [significance_str, '\nAll other comparisons p>0.05'];
else
    significance_str = [significance_str, 'No significant pairwise comparisons (all p>0.05)'];
end

% Create table structure
supp_table = table(...
    {'Fig. S5c'}, ...
    {'MBP coverage (%) of individual sections across layers and age groups'}, ...
    {values_str}, ...
    {n_str}, ...
    {stat_test_str}, ...
    {significance_str}, ...
    'VariableNames', {'Supplemental_Fig', 'Measure', 'Values', 'N', 'Statistical_test', 'Significance'});

% Save to CSV
writetable(supp_table, 'MBP_Supplemental_Table.csv');
fprintf('\nSupplemental table saved to "MBP_Supplemental_Table.csv"\n');

% Also save a more readable text version
fid_supp = fopen('MBP_Supplemental_Table.txt', 'w');
fprintf(fid_supp, '========================================================\n');
fprintf(fid_supp, 'SUPPLEMENTAL TABLE - MBP Coverage Analysis\n');
fprintf(fid_supp, '========================================================\n\n');

fprintf(fid_supp, 'Figure: Fig. S5c\n\n');

fprintf(fid_supp, 'Measure:\n');
fprintf(fid_supp, 'MBP coverage (%%) of individual sections across layers and age groups\n\n');

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

fprintf('Readable supplemental table saved to "MBP_Supplemental_Table.txt"\n');

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
fprintf('  1. MBP_Coverage_by_Age_Layer.png\n');
fprintf('  2. MBP_Supplemental_Table.csv\n');
fprintf('  3. MBP_Supplemental_Table.txt\n\n');

fprintf('=== ANALYSIS COMPLETE ===\n\n');