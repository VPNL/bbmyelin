% MBP Coverage Analysis with Layer
% Linear Mixed-Effects Model: MBP_coverage ~ Region*Age_group*Layer + (1|Slide_number)
% Author: [Your Name]
% Date: [Current Date]
% MATLAB Version: 2024b

%% Clear workspace
clear; clc; close all;

%% Load data
data = readtable('Fig1_d.csv');

%% Display data summary
fprintf('Dataset Summary:\n');
fprintf('================\n');
fprintf('Total observations: %d\n', height(data));
fprintf('Number of regions: %d\n', length(unique(data.Region)));
fprintf('Number of layers: %d\n', length(unique(data.Layer)));
fprintf('Number of unique slides: %d\n', length(unique(data.Slide_number)));
fprintf('Number of age groups: %d\n\n', length(unique(data.Age_group)));

fprintf('Observations per region:\n');
disp(tabulate(data.Region));

fprintf('Observations per layer:\n');
disp(tabulate(data.Layer));

fprintf('Observations per age group:\n');
disp(tabulate(data.Age_group));

%% Prepare variables
data.Region = categorical(data.Region);
data.Layer = categorical(data.Layer);
data.Slide_number = categorical(data.Slide_number);
data.Age_group = categorical(data.Age_group);

%% Fit Linear Mixed-Effects Model
fprintf('\nFitting linear mixed-effects model...\n');
fprintf('Model formula: MBP_coverage ~ Region*Age_group*Layer + (1|Slide_number)\n');
fprintf('Using REML estimation\n\n');

lme = fitlme(data, 'MBP_coverage ~ Region * Age_group * Layer + (1|Slide_number)', 'FitMethod', 'REML');

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

%% CUSTOM PLOTS: Mean ± SEM by Age Group, Region, and Layer
% Get unique layers
layers = categories(data.Layer);
age_groups = categories(data.Age_group);
regions_ordered = {'Calc', 'CoS', 'FG'};

% Define custom colors: Calc=purple, FG=pink, CoS=green
region_colors = containers.Map({'Calc', 'FG', 'CoS'}, ...
                               {[0.6, 0.2, 0.8], [1, 0.4, 0.7], [0.2, 0.8, 0.4]});

% Create separate plots for each layer
for layer_idx = 1:length(layers)
    layer_name = char(layers{layer_idx});
    layer_data = data(data.Layer == layers{layer_idx}, :);
    
    figure('Position', [100, 100, 1000, 600]);
    
    n_groups = length(age_groups);
    
    for i = 1:length(regions_ordered)
        region_name = regions_ordered{i};
        region_data = layer_data(layer_data.Region == region_name, :);
        
        means = zeros(n_groups, 1);
        sems = zeros(n_groups, 1);
        x_positions = 1:n_groups;
        
        for j = 1:n_groups
            group_data = region_data(region_data.Age_group == age_groups{j}, :);
            if ~isempty(group_data)
                means(j) = mean(group_data.MBP_coverage);
                sems(j) = std(group_data.MBP_coverage) / sqrt(height(group_data));
            else
                means(j) = NaN;
                sems(j) = NaN;
            end
        end
        
        % Plot mean as dots with error bars
        errorbar(x_positions, means, sems, 'o', ...
                 'Color', region_colors(region_name), ...
                 'MarkerFaceColor', region_colors(region_name), ...
                 'MarkerSize', 10, ...
                 'LineWidth', 2, ...
                 'CapSize', 8, ...
                 'DisplayName', region_name);
        hold on;
    end
    
    set(gca, 'XTick', 1:n_groups, 'XTickLabel', age_groups);
    xtickangle(45);
    xlabel('Age Group', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('MBP Coverage (%)', 'FontSize', 14, 'FontWeight', 'bold');
    title(sprintf('MBP Coverage - %s', layer_name), 'FontSize', 16, 'FontWeight', 'bold');
    legend('Location', 'northwest', 'FontSize', 12);
    grid on;
    box on;
    set(gca, 'FontSize', 12);
    
    filename = sprintf('MBP_age_group_means_%s.png', layer_name);
    saveas(gcf, filename);
    fprintf('Mean±SEM plot for %s saved as "%s"\n', layer_name, filename);
end

%% Generate Supplemental Table
fprintf('\n========================================\n');
fprintf('GENERATING SUPPLEMENTAL TABLE\n');
fprintf('========================================\n\n');

% Get actual age groups from data
age_groups = categories(data.Age_group);
regions_ordered = {'Calc', 'FG', 'CoS'};
layers = categories(data.Layer);

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

for layer_idx = 1:length(layers)
    layer_name = char(layers{layer_idx});
    values_str = [values_str, sprintf('\n%s:\n', layer_name)];
    
    for i = 1:length(age_groups)
        ag = age_groups{i};
        age_label = age_labels_clean{i};
        values_str = [values_str, sprintf('  %s:\n', age_label)];
        
        for j = 1:length(regions_ordered)
            region = regions_ordered{j};
            subset = data(data.Age_group == ag & data.Region == region & data.Layer == layers{layer_idx}, :);
            
            if ~isempty(subset)
                mean_val = mean(subset.MBP_coverage);
                sem_val = std(subset.MBP_coverage) / sqrt(height(subset));
                values_str = [values_str, sprintf('    %s: %.2f±%.2f\n', region, mean_val, sem_val)];
            end
        end
    end
end

% Count total sections per layer and age group
for layer_idx = 1:length(layers)
    layer_name = char(layers{layer_idx});
    n_str = [n_str, sprintf('\n%s:\n', layer_name)];
    
    for i = 1:length(age_groups)
        ag = age_groups{i};
        age_label = age_labels_clean{i};
        n_sections = sum(data.Age_group == ag & data.Layer == layers{layer_idx});
        n_str = [n_str, sprintf('  %s: %d sections\n', age_label, n_sections)];
    end
end

% Build statistical test string
stat_test_str = sprintf('Dataset (n=%d sections):\n', height(data));
stat_test_str = [stat_test_str, sprintf(['Restricted Maximum Likelihood model (REML) to predict MBP coverage with ', ...
    'categorical Age_group, Region (Calc vs. FG vs. CoS), and Layer, ', ...
    'with full three-way interaction, and with random variable of section.\n\n'])];

% Add ANOVA results
age_group_idx = find(strcmp(anova_results.Term, 'Age_group'));
region_idx = find(strcmp(anova_results.Term, 'Region'));
layer_idx = find(strcmp(anova_results.Term, 'Layer'));
region_age_group_idx = find(strcmp(anova_results.Term, 'Region:Age_group') | strcmp(anova_results.Term, 'Age_group:Region'));
region_layer_idx = find(strcmp(anova_results.Term, 'Region:Layer') | strcmp(anova_results.Term, 'Layer:Region'));
age_group_layer_idx = find(strcmp(anova_results.Term, 'Age_group:Layer') | strcmp(anova_results.Term, 'Layer:Age_group'));
three_way_idx = find(contains(anova_results.Term, 'Region') & contains(anova_results.Term, 'Age_group') & contains(anova_results.Term, 'Layer'));

stat_test_str = [stat_test_str, sprintf('Main effect of Age_group (categorical): F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(age_group_idx), anova_results.DF2(age_group_idx), ...
    anova_results.FStat(age_group_idx), anova_results.pValue(age_group_idx))];

stat_test_str = [stat_test_str, sprintf('Main effect of Region: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(region_idx), anova_results.DF2(region_idx), ...
    anova_results.FStat(region_idx), anova_results.pValue(region_idx))];

stat_test_str = [stat_test_str, sprintf('Main effect of Layer: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(layer_idx), anova_results.DF2(layer_idx), ...
    anova_results.FStat(layer_idx), anova_results.pValue(layer_idx))];

stat_test_str = [stat_test_str, sprintf('Region × Age_group interaction: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(region_age_group_idx), anova_results.DF2(region_age_group_idx), ...
    anova_results.FStat(region_age_group_idx), anova_results.pValue(region_age_group_idx))];

stat_test_str = [stat_test_str, sprintf('Region × Layer interaction: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(region_layer_idx), anova_results.DF2(region_layer_idx), ...
    anova_results.FStat(region_layer_idx), anova_results.pValue(region_layer_idx))];

stat_test_str = [stat_test_str, sprintf('Age_group × Layer interaction: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(age_group_layer_idx), anova_results.DF2(age_group_layer_idx), ...
    anova_results.FStat(age_group_layer_idx), anova_results.pValue(age_group_layer_idx))];

stat_test_str = [stat_test_str, sprintf('Region × Age_group × Layer interaction: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(three_way_idx), anova_results.DF2(three_way_idx), ...
    anova_results.FStat(three_way_idx), anova_results.pValue(three_way_idx))];

stat_test_str = [stat_test_str, sprintf('R²=%.2f\n', lme.Rsquared.Ordinary)];

%% Perform post-hoc pairwise comparisons
fprintf('\nPerforming post-hoc pairwise comparisons...\n');

posthoc_results = {};

% PART 1: Region comparisons within each age group and layer
fprintf('\nRegion comparisons within each age group and layer:\n');
for layer_idx = 1:length(layers)
    layer_name = char(layers{layer_idx});
    
    for i = 1:length(age_groups)
        ag = age_groups{i};
        age_label = age_labels_clean{i};
        
        % Get data for this age group and layer
        subset = data(data.Age_group == ag & data.Layer == layers{layer_idx}, :);
        
        if isempty(subset)
            continue;
        end
        
        % Compare all region pairs
        region_pairs = {{'Calc', 'CoS'}, {'Calc', 'FG'}, {'CoS', 'FG'}};
        
        for j = 1:length(region_pairs)
            region1 = region_pairs{j}{1};
            region2 = region_pairs{j}{2};
            
            data1 = subset(subset.Region == region1, :);
            data2 = subset(subset.Region == region2, :);
            
            if ~isempty(data1) && ~isempty(data2)
                [h, p] = ttest2(data1.MBP_coverage, data2.MBP_coverage);
                
                comparison = sprintf('%s, %s, %s vs. %s, %s, %s', ...
                                   region1, age_label, layer_name, region2, age_label, layer_name);
                
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

% PART 2: Layer comparisons within each age group and region
fprintf('\nLayer comparisons within each age group and region:\n');
layer_pairs_list = {};
for i = 1:length(layers)-1
    for j = i+1:length(layers)
        layer_pairs_list{end+1} = {char(layers{i}), char(layers{j})};
    end
end

for r = 1:length(regions_ordered)
    region = regions_ordered{r};
    
    for i = 1:length(age_groups)
        ag = age_groups{i};
        age_label = age_labels_clean{i};
        
        % Get data for this region and age group
        subset = data(data.Region == region & data.Age_group == ag, :);
        
        if isempty(subset)
            continue;
        end
        
        % Compare all layer pairs
        for j = 1:length(layer_pairs_list)
            layer1 = layer_pairs_list{j}{1};
            layer2 = layer_pairs_list{j}{2};
            
            data1 = subset(subset.Layer == layer1, :);
            data2 = subset(subset.Layer == layer2, :);
            
            if ~isempty(data1) && ~isempty(data2)
                [h, p] = ttest2(data1.MBP_coverage, data2.MBP_coverage);
                
                comparison = sprintf('%s, %s, %s vs. %s, %s, %s', ...
                                   region, age_label, layer1, region, age_label, layer2);
                
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
    {'Fig. 1d'}, ...
    {'MBP coverage (%) of individual sections in Calc, CoS, and FG across age groups and layers'}, ...
    {values_str}, ...
    {n_str}, ...
    {stat_test_str}, ...
    {significance_str}, ...
    'VariableNames', {'Supplemental_Fig', 'Measure', 'Values', 'N', 'Statistical_test', 'Significance'});

% Save to CSV
writetable(supp_table, 'MBP_Layer_Supplemental_Table.csv');
fprintf('\nSupplemental table saved to "MBP_Layer_Supplemental_Table.csv"\n');

% Also save a more readable text version
fid_supp = fopen('MBP_Layer_Supplemental_Table.txt', 'w');
fprintf(fid_supp, '========================================================\n');
fprintf(fid_supp, 'SUPPLEMENTAL TABLE - MBP Coverage Analysis with Layer\n');
fprintf(fid_supp, '========================================================\n\n');

fprintf(fid_supp, 'Figure: Fig. 1d\n\n');

fprintf(fid_supp, 'Measure:\n');
fprintf(fid_supp, 'MBP coverage (%%) of individual sections in Calc, CoS, and FG across age groups and layers\n\n');

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

fprintf('Readable supplemental table saved to "MBP_Layer_Supplemental_Table.txt"\n');

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
num_layers = length(layers);
for layer_idx = 1:num_layers
    layer_name = char(layers{layer_idx});
    fprintf('  %d. MBP_age_group_means_%s.png\n', layer_idx, layer_name);
end
fprintf('  %d. MBP_Layer_Supplemental_Table.csv\n', num_layers+1);
fprintf('  %d. MBP_Layer_Supplemental_Table.txt\n\n', num_layers+2);

fprintf('=== ANALYSIS COMPLETE ===\n\n');