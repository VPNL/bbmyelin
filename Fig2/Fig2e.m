% Olig2 density_mm2 Analysis with Layer
% Linear Mixed-Effects Model: Olig2_density_mm2 ~ Region*Age*Layer + (1|Slide_number)
% Author: [Your Name]
% Date: [Current Date]
% MATLAB Version: 2024b

%% Clear workspace
clear; clc; close all;

%% Load data
data = readtable('Fig2_e.csv');

%% Display data summary
fprintf('Dataset Summary:\n');
fprintf('================\n');
fprintf('Total observations: %d\n', height(data));
fprintf('Number of regions: %d\n', length(unique(data.Region)));
fprintf('Number of layers: %d\n', length(unique(data.Layer)));
fprintf('Number of unique slides: %d\n', length(unique(data.Slide_number)));
fprintf('Age range: %.1f - %.1f months\n\n', min(data.Age), max(data.Age));

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
fprintf('Model formula: Olig2_density_mm2 ~ Region*Age*Layer + (1|Slide_number)\n');
fprintf('Using REML estimation\n\n');

lme = fitlme(data, 'Olig2_density_mm2 ~ Region * Age * Layer + (1|Slide_number)', 'FitMethod', 'REML');

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
regions_ordered = {'Calc', 'CoS', 'FG'};

% Define custom colors: Calc=purple, FG=pink, CoS=green
region_colors = containers.Map({'Calc', 'FG', 'CoS'}, ...
                               {[0.6, 0.2, 0.8], [1, 0.4, 0.7], [0.2, 0.8, 0.4]});

%% PLOT 1: Regions WITHOUT Layer Separation - Mean ± SEM by Age Group and Region
fprintf('\nGenerating plot: Regions across age groups (layers combined)...\n');

figure('Position', [100, 100, 1000, 600]);

n_groups = length(age_groups);

for i = 1:length(regions_ordered)
    region_name = regions_ordered{i};
    region_data = data(data.Region == region_name, :);
    
    means = zeros(n_groups, 1);
    sems = zeros(n_groups, 1);
    x_positions = 1:n_groups;
    
    for j = 1:n_groups
        group_data = region_data(region_data.Age_group == age_groups{j}, :);
        if ~isempty(group_data)
            means(j) = mean(group_data.Olig2_density_mm2);
            sems(j) = std(group_data.Olig2_density_mm2) / sqrt(height(group_data));
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
ylabel('Olig2 density (cells/mm^2)', 'FontSize', 14, 'FontWeight', 'bold');
title('Olig2 Density Across Regions (All Layers Combined)', 'FontSize', 16, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 12);
grid on;
box on;
set(gca, 'FontSize', 12);

filename = 'Olig2_density_regions_all_layers.png';
saveas(gcf, filename);
fprintf('Plot saved as "%s"\n', filename);

%% PLOT 2: Regions Separated by Layer - Mean ± SEM by Age Group, Region, and Layer
fprintf('\nGenerating plots: Regions by layer...\n');

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
                means(j) = mean(group_data.Olig2_density_mm2);
                sems(j) = std(group_data.Olig2_density_mm2) / sqrt(height(group_data));
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
    ylabel('Olig2 density (cells/mm^2)', 'FontSize', 14, 'FontWeight', 'bold');
    title(sprintf('Olig2 Density - %s', layer_name), 'FontSize', 16, 'FontWeight', 'bold');
    legend('Location', 'northwest', 'FontSize', 12);
    grid on;
    box on;
    set(gca, 'FontSize', 12);
    
    filename = sprintf('Olig2_density_%s.png', layer_name);
    saveas(gcf, filename);
    fprintf('Plot for %s saved as "%s"\n', layer_name, filename);
end

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
                mean_val = mean(subset.Olig2_density_mm2);
                sem_val = std(subset.Olig2_density_mm2) / sqrt(height(subset));
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
stat_test_str = sprintf('Dataset (0-24 months, n=%d sections):\n', height(data));
stat_test_str = [stat_test_str, sprintf(['Restricted Maximum Likelihood model (REML) to predict Olig2 density with ', ...
    'continuous Age (in months), Region (Calc vs. FG vs. CoS), and Layer, ', ...
    'with full three-way interaction, and with random variable of section.\n\n'])];

% Add ANOVA results
age_idx = find(strcmp(anova_results.Term, 'Age'));
region_idx = find(strcmp(anova_results.Term, 'Region'));
layer_idx = find(strcmp(anova_results.Term, 'Layer'));
region_age_idx = find(strcmp(anova_results.Term, 'Region:Age') | strcmp(anova_results.Term, 'Age:Region'));
region_layer_idx = find(strcmp(anova_results.Term, 'Region:Layer') | strcmp(anova_results.Term, 'Layer:Region'));
age_layer_idx = find(strcmp(anova_results.Term, 'Age:Layer') | strcmp(anova_results.Term, 'Layer:Age'));

% Fixed: Find three-way interaction with all possible orderings
three_way_idx = find(strcmp(anova_results.Term, 'Region:Age:Layer') | ...
                     strcmp(anova_results.Term, 'Age:Region:Layer') | ...
                     strcmp(anova_results.Term, 'Layer:Region:Age') | ...
                     strcmp(anova_results.Term, 'Region:Layer:Age') | ...
                     strcmp(anova_results.Term, 'Age:Layer:Region') | ...
                     strcmp(anova_results.Term, 'Layer:Age:Region'));

stat_test_str = [stat_test_str, sprintf('Main effect of Age (continuous): F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(age_idx), anova_results.DF2(age_idx), ...
    anova_results.FStat(age_idx), anova_results.pValue(age_idx))];

stat_test_str = [stat_test_str, sprintf('Main effect of Region: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(region_idx), anova_results.DF2(region_idx), ...
    anova_results.FStat(region_idx), anova_results.pValue(region_idx))];

stat_test_str = [stat_test_str, sprintf('Main effect of Layer: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(layer_idx), anova_results.DF2(layer_idx), ...
    anova_results.FStat(layer_idx), anova_results.pValue(layer_idx))];

stat_test_str = [stat_test_str, sprintf('Region × Age interaction: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(region_age_idx), anova_results.DF2(region_age_idx), ...
    anova_results.FStat(region_age_idx), anova_results.pValue(region_age_idx))];

stat_test_str = [stat_test_str, sprintf('Region × Layer interaction: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(region_layer_idx), anova_results.DF2(region_layer_idx), ...
    anova_results.FStat(region_layer_idx), anova_results.pValue(region_layer_idx))];

stat_test_str = [stat_test_str, sprintf('Age × Layer interaction: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(age_layer_idx), anova_results.DF2(age_layer_idx), ...
    anova_results.FStat(age_layer_idx), anova_results.pValue(age_layer_idx))];

stat_test_str = [stat_test_str, sprintf('Region × Age × Layer interaction: F(%d,%d)=%.2f, p=%.4f\n', ...
    anova_results.DF1(three_way_idx), anova_results.DF2(three_way_idx), ...
    anova_results.FStat(three_way_idx), anova_results.pValue(three_way_idx))];

stat_test_str = [stat_test_str, sprintf('R²=%.2f\n', lme.Rsquared.Ordinary)];

%% Perform post-hoc pairwise comparisons
fprintf('\nPerforming post-hoc pairwise comparisons...\n');

posthoc_results = {};

% Get p-values for main effects and interactions
p_region = anova_results.pValue(region_idx);
p_layer = anova_results.pValue(layer_idx);
p_age = anova_results.pValue(age_idx);
p_region_age = anova_results.pValue(region_age_idx);
p_region_layer = anova_results.pValue(region_layer_idx);
p_age_layer = anova_results.pValue(age_layer_idx);
p_three_way = anova_results.pValue(three_way_idx);

fprintf('\nSignificance of effects:\n');
fprintf('  Region: p=%.4f %s\n', p_region, ternary(p_region < 0.05, '(SIGNIFICANT)', '(not significant)'));
fprintf('  Layer: p=%.4f %s\n', p_layer, ternary(p_layer < 0.05, '(SIGNIFICANT)', '(not significant)'));
fprintf('  Age: p=%.4f %s\n', p_age, ternary(p_age < 0.05, '(SIGNIFICANT)', '(not significant)'));
fprintf('  Region × Age: p=%.4f %s\n', p_region_age, ternary(p_region_age < 0.05, '(SIGNIFICANT)', '(not significant)'));
fprintf('  Region × Layer: p=%.4f %s\n', p_region_layer, ternary(p_region_layer < 0.05, '(SIGNIFICANT)', '(not significant)'));
fprintf('  Age × Layer: p=%.4f %s\n', p_age_layer, ternary(p_age_layer < 0.05, '(SIGNIFICANT)', '(not significant)'));
fprintf('  Region × Age × Layer: p=%.4f %s\n\n', p_three_way, ternary(p_three_way < 0.05, '(SIGNIFICANT)', '(not significant)'));

% Determine which post-hoc tests to run based on significant effects
run_region_posthoc = (p_region < 0.05);
run_layer_posthoc = (p_layer < 0.05);
run_region_layer_interaction = (p_region_layer < 0.05);
run_three_way_interaction = (p_three_way < 0.05);

% PART 1: Region comparisons within each age group and layer (only if three-way interaction is significant)
if run_three_way_interaction
    fprintf('\nThree-way interaction is significant - performing region comparisons within each age group and layer:\n');
    
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
                    [h, p] = ttest2(data1.Olig2_density_mm2, data2.Olig2_density_mm2);
                    
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
elseif run_region_layer_interaction
    fprintf('\nRegion × Layer interaction is significant - performing region comparisons within each layer (collapsed across age):\n');
    
    for layer_idx = 1:length(layers)
        layer_name = char(layers{layer_idx});
        
        % Get data for this layer (collapsed across age)
        subset = data(data.Layer == layers{layer_idx}, :);
        
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
                [h, p] = ttest2(data1.Olig2_density_mm2, data2.Olig2_density_mm2);
                
                comparison = sprintf('%s, %s vs. %s, %s', ...
                                   region1, layer_name, region2, layer_name);
                
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
elseif run_region_posthoc
    fprintf('\nMain effect of Region is significant - performing overall region comparisons (collapsed across age and layer):\n');
    
    region_pairs = {{'Calc', 'CoS'}, {'Calc', 'FG'}, {'CoS', 'FG'}};
    
    for j = 1:length(region_pairs)
        region1 = region_pairs{j}{1};
        region2 = region_pairs{j}{2};
        
        data1 = data(data.Region == region1, :);
        data2 = data(data.Region == region2, :);
        
        if ~isempty(data1) && ~isempty(data2)
            [h, p] = ttest2(data1.Olig2_density_mm2, data2.Olig2_density_mm2);
            
            comparison = sprintf('%s vs. %s (all ages and layers)', region1, region2);
            
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

% PART 2: Layer comparisons (only if relevant effects are significant)
if run_three_way_interaction
    fprintf('\nThree-way interaction is significant - performing layer comparisons within each region and age group:\n');
    
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
                    [h, p] = ttest2(data1.Olig2_density_mm2, data2.Olig2_density_mm2);
                    
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
elseif run_region_layer_interaction
    fprintf('\nRegion × Layer interaction is significant - performing layer comparisons within each region (collapsed across age):\n');
    
    layer_pairs_list = {};
    for i = 1:length(layers)-1
        for j = i+1:length(layers)
            layer_pairs_list{end+1} = {char(layers{i}), char(layers{j})};
        end
    end
    
    for r = 1:length(regions_ordered)
        region = regions_ordered{r};
        
        % Get data for this region (collapsed across age)
        subset = data(data.Region == region, :);
        
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
                [h, p] = ttest2(data1.Olig2_density_mm2, data2.Olig2_density_mm2);
                
                comparison = sprintf('%s, %s vs. %s, %s', ...
                                   region, layer1, region, layer2);
                
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
elseif run_layer_posthoc
    fprintf('\nMain effect of Layer is significant - performing overall layer comparisons (collapsed across region and age):\n');
    
    layer_pairs_list = {};
    for i = 1:length(layers)-1
        for j = i+1:length(layers)
            layer_pairs_list{end+1} = {char(layers{i}), char(layers{j})};
        end
    end
    
    for j = 1:length(layer_pairs_list)
        layer1 = layer_pairs_list{j}{1};
        layer2 = layer_pairs_list{j}{2};
        
        data1 = data(data.Layer == layer1, :);
        data2 = data(data.Layer == layer2, :);
        
        if ~isempty(data1) && ~isempty(data2)
            [h, p] = ttest2(data1.Olig2_density_mm2, data2.Olig2_density_mm2);
            
            comparison = sprintf('%s vs. %s (all regions and ages)', layer1, layer2);
            
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

% If no significant effects, report that
if ~run_region_posthoc && ~run_layer_posthoc && ~run_region_layer_interaction && ~run_three_way_interaction
    fprintf('\nNo significant main effects or interactions found.\n');
    fprintf('Post-hoc pairwise comparisons not performed.\n');
end

% Build significance string
significance_str = 'Post-hoc pairwise comparisons using Student''s t-test:\n\n';
if ~isempty(posthoc_results)
    for i = 1:length(posthoc_results)
        significance_str = [significance_str, posthoc_results{i}, '\n'];
    end
    significance_str = [significance_str, '\nAll other comparisons p>0.05'];
else
    if ~run_region_posthoc && ~run_layer_posthoc && ~run_region_layer_interaction && ~run_three_way_interaction
        significance_str = [significance_str, 'No significant main effects or interactions detected.\n'];
        significance_str = [significance_str, 'Post-hoc pairwise comparisons not performed.'];
    else
        significance_str = [significance_str, 'No significant pairwise comparisons (all p>0.05)'];
    end
end

% Create table structure
supp_table = table(...
    {'Fig. 2e'}, ...
    {'Olig2 density (cells/mm²) of individual sections in Calc, CoS, and FG across age groups and layers'}, ...
    {values_str}, ...
    {n_str}, ...
    {stat_test_str}, ...
    {significance_str}, ...
    'VariableNames', {'Supplemental_Fig', 'Measure', 'Values', 'N', 'Statistical_test', 'Significance'});

% Save to CSV
writetable(supp_table, 'Olig2_Layer_Supplemental_Table.csv');
fprintf('\nSupplemental table saved to "Olig2_Layer_Supplemental_Table.csv"\n');

% Also save a more readable text version
fid_supp = fopen('Olig2_Layer_Supplemental_Table.txt', 'w');
fprintf(fid_supp, '========================================================\n');
fprintf(fid_supp, 'SUPPLEMENTAL TABLE - Olig2 Density Analysis with Layer\n');
fprintf(fid_supp, '========================================================\n\n');

fprintf(fid_supp, 'Figure: Fig. 2e\n\n');

fprintf(fid_supp, 'Measure:\n');
fprintf(fid_supp, 'Olig2 density (cells/mm²) of individual sections in Calc, CoS, and FG across age groups and layers\n\n');

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

fprintf('Readable supplemental table saved to "Olig2_Layer_Supplemental_Table.txt"\n');

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
fprintf('  1. Olig2_density_regions_all_layers.png\n');
num_layers = length(layers);
for layer_idx = 1:num_layers
    layer_name = char(layers{layer_idx});
    fprintf('  %d. Olig2_density_%s.png\n', layer_idx+1, layer_name);
end
fprintf('  %d. Olig2_Layer_Supplemental_Table.csv\n', num_layers+2);
fprintf('  %d. Olig2_Layer_Supplemental_Table.txt\n\n', num_layers+3);


% One-Sample T-Test for Neonate Age Group
% Tests whether Olig2 density in neonates is significantly greater than 0
% Author: [Your Name]
% Date: [Current Date]

%% Clear workspace
clear; clc; close all;

%% Load data
data = readtable('Fig2_e.csv');

%% Prepare variables
data.Region = categorical(data.Region);
data.Layer = categorical(data.Layer);
data.Age_group = categorical(data.Age_group);

%% Extract neonate data
neonate_data = data(data.Age_group == 'a_neonate', :);

fprintf('========================================\n');
fprintf('ONE-SAMPLE T-TEST: NEONATE AGE GROUP\n');
fprintf('========================================\n\n');

fprintf('Testing if Olig2 density in neonates is greater than 0\n');
fprintf('Null hypothesis: μ = 0\n');
fprintf('Alternative hypothesis: μ > 0 (right-tailed test)\n\n');

%% Overall neonate analysis
fprintf('--- OVERALL NEONATE DATA ---\n');
fprintf('Sample size: %d sections\n', height(neonate_data));
fprintf('Mean Olig2 density: %.2f cells/mm²\n', mean(neonate_data.Olig2_density_mm2));
fprintf('SEM: %.2f cells/mm²\n', std(neonate_data.Olig2_density_mm2) / sqrt(height(neonate_data)));
fprintf('SD: %.2f cells/mm²\n', std(neonate_data.Olig2_density_mm2));
fprintf('Range: %.2f - %.2f cells/mm²\n\n', min(neonate_data.Olig2_density_mm2), max(neonate_data.Olig2_density_mm2));

% Perform one-sample t-test (right-tailed)
[h, p, ci, stats] = ttest(neonate_data.Olig2_density_mm2, 0, 'Tail', 'right');

fprintf('One-sample t-test results:\n');
fprintf('  t(%d) = %.4f\n', stats.df, stats.tstat);
fprintf('  p-value (one-tailed) = %.4e\n', p);
fprintf('  95%% CI: [%.2f, Inf]\n', ci(1));
fprintf('  Cohen''s d = %.4f\n\n', stats.tstat / sqrt(height(neonate_data)));

if h == 1
    fprintf('Result: SIGNIFICANT (p < 0.05)\n');
    fprintf('Conclusion: Neonate Olig2 density is significantly greater than 0.\n\n');
else
    fprintf('Result: NOT SIGNIFICANT (p >= 0.05)\n');
    fprintf('Conclusion: No evidence that neonate Olig2 density differs from 0.\n\n');
end

%% Analysis by Region
regions = {'Calc', 'CoS', 'FG'};

fprintf('\n--- BY REGION ---\n');
region_results = table();

for i = 1:length(regions)
    region_name = regions{i};
    region_subset = neonate_data(neonate_data.Region == region_name, :);
    
    if ~isempty(region_subset)
        n = height(region_subset);
        mean_val = mean(region_subset.Olig2_density_mm2);
        sem_val = std(region_subset.Olig2_density_mm2) / sqrt(n);
        
        [h, p, ci, stats] = ttest(region_subset.Olig2_density_mm2, 0, 'Tail', 'right');
        
        fprintf('\n%s:\n', region_name);
        fprintf('  n = %d sections\n', n);
        fprintf('  Mean±SEM = %.2f±%.2f cells/mm²\n', mean_val, sem_val);
        fprintf('  t(%d) = %.4f, p = %.4e\n', stats.df, stats.tstat, p);
        fprintf('  95%% CI: [%.2f, Inf]\n', ci(1));
        
        if h == 1
            fprintf('  Significant: YES\n');
        else
            fprintf('  Significant: NO\n');
        end
        
        % Store results
        region_results = [region_results; table({region_name}, n, mean_val, sem_val, ...
                         stats.tstat, stats.df, p, h, ...
                         'VariableNames', {'Region', 'N', 'Mean', 'SEM', 't_stat', 'df', 'p_value', 'Significant'})];
    end
end

%% Analysis by Layer
layers = categories(neonate_data.Layer);

fprintf('\n--- BY LAYER ---\n');
layer_results = table();

for i = 1:length(layers)
    layer_name = char(layers{i});
    layer_subset = neonate_data(neonate_data.Layer == layers{i}, :);
    
    if ~isempty(layer_subset)
        n = height(layer_subset);
        mean_val = mean(layer_subset.Olig2_density_mm2);
        sem_val = std(layer_subset.Olig2_density_mm2) / sqrt(n);
        
        [h, p, ci, stats] = ttest(layer_subset.Olig2_density_mm2, 0, 'Tail', 'right');
        
        fprintf('\n%s:\n', layer_name);
        fprintf('  n = %d sections\n', n);
        fprintf('  Mean±SEM = %.2f±%.2f cells/mm²\n', mean_val, sem_val);
        fprintf('  t(%d) = %.4f, p = %.4e\n', stats.df, stats.tstat, p);
        fprintf('  95%% CI: [%.2f, Inf]\n', ci(1));
        
        if h == 1
            fprintf('  Significant: YES\n');
        else
            fprintf('  Significant: NO\n');
        end
        
        % Store results
        layer_results = [layer_results; table({layer_name}, n, mean_val, sem_val, ...
                        stats.tstat, stats.df, p, h, ...
                        'VariableNames', {'Layer', 'N', 'Mean', 'SEM', 't_stat', 'df', 'p_value', 'Significant'})];
    end
end

%% Analysis by Region AND Layer
fprintf('\n--- BY REGION AND LAYER ---\n');
region_layer_results = table();

for i = 1:length(regions)
    region_name = regions{i};
    
    for j = 1:length(layers)
        layer_name = char(layers{j});
        
        subset = neonate_data(neonate_data.Region == region_name & ...
                             neonate_data.Layer == layers{j}, :);
        
        if ~isempty(subset)
            n = height(subset);
            mean_val = mean(subset.Olig2_density_mm2);
            sem_val = std(subset.Olig2_density_mm2) / sqrt(n);
            
            [h, p, ci, stats] = ttest(subset.Olig2_density_mm2, 0, 'Tail', 'right');
            
            fprintf('\n%s - %s:\n', region_name, layer_name);
            fprintf('  n = %d sections\n', n);
            fprintf('  Mean±SEM = %.2f±%.2f cells/mm²\n', mean_val, sem_val);
            fprintf('  t(%d) = %.4f, p = %.4e\n', stats.df, stats.tstat, p);
            fprintf('  95%% CI: [%.2f, Inf]\n', ci(1));
            
            if h == 1
                fprintf('  Significant: YES\n');
            else
                fprintf('  Significant: NO\n');
            end
            
            % Store results
            region_layer_results = [region_layer_results; table({region_name}, {layer_name}, ...
                                   n, mean_val, sem_val, stats.tstat, stats.df, p, h, ...
                                   'VariableNames', {'Region', 'Layer', 'N', 'Mean', 'SEM', ...
                                   't_stat', 'df', 'p_value', 'Significant'})];
        end
    end
end

%% Save results to files
fprintf('\n========================================\n');
fprintf('SAVING RESULTS\n');
fprintf('========================================\n\n');

% Save comprehensive text file with ALL results
fid = fopen('one_sample_neonate_complete_results.txt', 'w');
fprintf(fid, '========================================================\n');
fprintf(fid, 'ONE-SAMPLE T-TEST: NEONATE OLIG2 DENSITY > 0\n');
fprintf(fid, '========================================================\n\n');
fprintf(fid, 'Test: One-sample t-test (right-tailed)\n');
fprintf(fid, 'Null hypothesis: μ = 0\n');
fprintf(fid, 'Alternative hypothesis: μ > 0\n');
fprintf(fid, 'Significance level: α = 0.05\n\n');

% Overall results
fprintf(fid, '========================================================\n');
fprintf(fid, 'OVERALL NEONATE DATA\n');
fprintf(fid, '========================================================\n');
fprintf(fid, 'Sample size: n = %d sections\n', height(neonate_data));
fprintf(fid, 'Mean = %.2f cells/mm²\n', mean(neonate_data.Olig2_density_mm2));
fprintf(fid, 'SEM = %.2f cells/mm²\n', std(neonate_data.Olig2_density_mm2) / sqrt(height(neonate_data)));
fprintf(fid, 'SD = %.2f cells/mm²\n', std(neonate_data.Olig2_density_mm2));
fprintf(fid, 'Range: %.2f - %.2f cells/mm²\n\n', min(neonate_data.Olig2_density_mm2), max(neonate_data.Olig2_density_mm2));

[h, p, ci, stats] = ttest(neonate_data.Olig2_density_mm2, 0, 'Tail', 'right');
fprintf(fid, 't(%d) = %.4f\n', stats.df, stats.tstat);
fprintf(fid, 'p-value = %.4e\n', p);
fprintf(fid, '95%% CI: [%.2f, Inf]\n', ci(1));
fprintf(fid, 'Cohen''s d = %.4f\n\n', stats.tstat / sqrt(height(neonate_data)));

if h == 1
    fprintf(fid, 'Result: SIGNIFICANT (p < 0.05)\n');
    fprintf(fid, 'Conclusion: Neonate Olig2 density is significantly greater than 0.\n\n');
else
    fprintf(fid, 'Result: NOT SIGNIFICANT (p >= 0.05)\n');
    fprintf(fid, 'Conclusion: No evidence that neonate Olig2 density differs from 0.\n\n');
end

% By Region
fprintf(fid, '\n========================================================\n');
fprintf(fid, 'ANALYSIS BY REGION\n');
fprintf(fid, '========================================================\n\n');

for i = 1:height(region_results)
    fprintf(fid, '%s:\n', region_results.Region{i});
    fprintf(fid, '  n = %d sections\n', region_results.N(i));
    fprintf(fid, '  Mean±SEM = %.2f±%.2f cells/mm²\n', region_results.Mean(i), region_results.SEM(i));
    fprintf(fid, '  t(%d) = %.4f\n', region_results.df(i), region_results.t_stat(i));
    fprintf(fid, '  p-value = %.4e\n', region_results.p_value(i));
    
    if region_results.Significant(i) == 1
        fprintf(fid, '  Result: SIGNIFICANT (p < 0.05)\n\n');
    else
        fprintf(fid, '  Result: NOT SIGNIFICANT (p >= 0.05)\n\n');
    end
end

% By Layer
fprintf(fid, '\n========================================================\n');
fprintf(fid, 'ANALYSIS BY LAYER\n');
fprintf(fid, '========================================================\n\n');

for i = 1:height(layer_results)
    fprintf(fid, '%s:\n', layer_results.Layer{i});
    fprintf(fid, '  n = %d sections\n', layer_results.N(i));
    fprintf(fid, '  Mean±SEM = %.2f±%.2f cells/mm²\n', layer_results.Mean(i), layer_results.SEM(i));
    fprintf(fid, '  t(%d) = %.4f\n', layer_results.df(i), layer_results.t_stat(i));
    fprintf(fid, '  p-value = %.4e\n', layer_results.p_value(i));
    
    if layer_results.Significant(i) == 1
        fprintf(fid, '  Result: SIGNIFICANT (p < 0.05)\n\n');
    else
        fprintf(fid, '  Result: NOT SIGNIFICANT (p >= 0.05)\n\n');
    end
end

% By Region AND Layer
fprintf(fid, '\n========================================================\n');
fprintf(fid, 'ANALYSIS BY REGION AND LAYER\n');
fprintf(fid, '========================================================\n\n');

for i = 1:height(region_layer_results)
    fprintf(fid, '%s - %s:\n', region_layer_results.Region{i}, region_layer_results.Layer{i});
    fprintf(fid, '  n = %d sections\n', region_layer_results.N(i));
    fprintf(fid, '  Mean±SEM = %.2f±%.2f cells/mm²\n', region_layer_results.Mean(i), region_layer_results.SEM(i));
    fprintf(fid, '  t(%d) = %.4f\n', region_layer_results.df(i), region_layer_results.t_stat(i));
    fprintf(fid, '  p-value = %.4e\n', region_layer_results.p_value(i));
    
    if region_layer_results.Significant(i) == 1
        fprintf(fid, '  Result: SIGNIFICANT (p < 0.05)\n\n');
    else
        fprintf(fid, '  Result: NOT SIGNIFICANT (p >= 0.05)\n\n');
    end
end

fprintf(fid, '========================================================\n');
fprintf(fid, 'END OF REPORT\n');
fprintf(fid, '========================================================\n');
fclose(fid);
fprintf('Complete results saved to "one_sample_neonate_complete_results.txt"\n');

% Save region results
writetable(region_results, 'one_sample_neonate_by_region.csv');
fprintf('Region-specific results saved to "one_sample_neonate_by_region.csv"\n');

% Save layer results
writetable(layer_results, 'one_sample_neonate_by_layer.csv');
fprintf('Layer-specific results saved to "one_sample_neonate_by_layer.csv"\n');

% Save region×layer results
writetable(region_layer_results, 'one_sample_neonate_by_region_layer.csv');
fprintf('Region×Layer results saved to "one_sample_neonate_by_region_layer.csv"\n');

%% Create visualization
fprintf('\nGenerating visualization...\n');

figure('Position', [100, 100, 1200, 800]);

% Define colors
region_colors = containers.Map({'Calc', 'FG', 'CoS'}, ...
                               {[0.6, 0.2, 0.8], [1, 0.4, 0.7], [0.2, 0.8, 0.4]});

% Subplot 1: By Region
subplot(2, 2, 1);
hold on;
for i = 1:height(region_results)
    bar(i, region_results.Mean(i), 'FaceColor', region_colors(region_results.Region{i}), ...
        'EdgeColor', 'k', 'LineWidth', 1.5);
    errorbar(i, region_results.Mean(i), region_results.SEM(i), 'k', 'LineWidth', 2, 'CapSize', 10);
end
set(gca, 'XTick', 1:height(region_results), 'XTickLabel', region_results.Region);
ylabel('Olig2 density (cells/mm²)', 'FontSize', 12, 'FontWeight', 'bold');
title('Neonate: By Region', 'FontSize', 14, 'FontWeight', 'bold');
grid on;
box on;
ylim([0, max(region_results.Mean + region_results.SEM) * 1.2]);

% Subplot 2: By Layer
subplot(2, 2, 2);
hold on;
bar_colors = [0.7, 0.7, 0.7; 0.5, 0.5, 0.5; 0.3, 0.3, 0.3];
for i = 1:height(layer_results)
    bar(i, layer_results.Mean(i), 'FaceColor', bar_colors(i, :), ...
        'EdgeColor', 'k', 'LineWidth', 1.5);
    errorbar(i, layer_results.Mean(i), layer_results.SEM(i), 'k', 'LineWidth', 2, 'CapSize', 10);
end
set(gca, 'XTick', 1:height(layer_results), 'XTickLabel', layer_results.Layer);
xtickangle(45);
ylabel('Olig2 density (cells/mm²)', 'FontSize', 12, 'FontWeight', 'bold');
title('Neonate: By Layer', 'FontSize', 14, 'FontWeight', 'bold');
grid on;
box on;
ylim([0, max(layer_results.Mean + layer_results.SEM) * 1.2]);

% Subplot 3: By Region and Layer (grouped bar chart)
subplot(2, 2, [3, 4]);
hold on;

bar_counter = 0;  % Counter for actual bar positions
x_positions = [];
group_labels = {};

for i = 1:length(regions)
    region_name = regions{i};
    region_subset = region_layer_results(strcmp(region_layer_results.Region, region_name), :);
    
    for j = 1:height(region_subset)
        bar_counter = bar_counter + 1;
        
        bar(bar_counter, region_subset.Mean(j), 'FaceColor', region_colors(region_name), ...
            'EdgeColor', 'k', 'LineWidth', 1.5);
        errorbar(bar_counter, region_subset.Mean(j), region_subset.SEM(j), 'k', ...
                'LineWidth', 2, 'CapSize', 10);
        
        x_positions(end+1) = bar_counter;
        % Format: "Region - Layer" on same line
        group_labels{end+1} = [region_name ' - ' region_subset.Layer{j}];
    end
    
    % Add spacing between regions
    if i < length(regions)
        bar_counter = bar_counter + 1;  % Add gap of 1
    end
end

set(gca, 'XTick', x_positions, 'XTickLabel', group_labels);
xtickangle(45);
ylabel('Olig2 density (cells/mm²)', 'FontSize', 12, 'FontWeight', 'bold');
title('Neonate: By Region and Layer', 'FontSize', 14, 'FontWeight', 'bold');
grid on;
box on;
set(gca, 'FontSize', 10);  % Make font slightly smaller to fit labels

sgtitle('One-Sample T-Test: Neonate Olig2 Density', 'FontSize', 16, 'FontWeight', 'bold');

saveas(gcf, 'one_sample_neonate_visualization.png');
fprintf('Visualization saved to "one_sample_neonate_visualization.png"\n');

%% Summary
fprintf('\n========================================\n');
fprintf('SUMMARY\n');
fprintf('========================================\n\n');

fprintf('All neonate sections (n=%d): ', height(neonate_data));
[h, p] = ttest(neonate_data.Olig2_density_mm2, 0, 'Tail', 'right');
if h == 1
    fprintf('SIGNIFICANT (p=%.4e)\n', p);
else
    fprintf('NOT SIGNIFICANT (p=%.4f)\n', p);
end

fprintf('\nBy Region:\n');
for i = 1:height(region_results)
    fprintf('  %s (n=%d): ', region_results.Region{i}, region_results.N(i));
    if region_results.Significant(i) == 1
        fprintf('SIGNIFICANT (p=%.4e)\n', region_results.p_value(i));
    else
        fprintf('NOT SIGNIFICANT (p=%.4f)\n', region_results.p_value(i));
    end
end

fprintf('\nBy Layer:\n');
for i = 1:height(layer_results)
    fprintf('  %s (n=%d): ', layer_results.Layer{i}, layer_results.N(i));
    if layer_results.Significant(i) == 1
        fprintf('SIGNIFICANT (p=%.4e)\n', layer_results.p_value(i));
    else
        fprintf('NOT SIGNIFICANT (p=%.4f)\n', layer_results.p_value(i));
    end
end

fprintf('\nBy Region and Layer:\n');
for i = 1:height(region_layer_results)
    fprintf('  %s - %s (n=%d): ', region_layer_results.Region{i}, region_layer_results.Layer{i}, region_layer_results.N(i));
    if region_layer_results.Significant(i) == 1
        fprintf('SIGNIFICANT (p=%.4e)\n', region_layer_results.p_value(i));
    else
        fprintf('NOT SIGNIFICANT (p=%.4f)\n', region_layer_results.p_value(i));
    end
end

fprintf('\n=== Analysis Complete ===\n');
fprintf('Files generated:\n');
fprintf('  1. one_sample_neonate_complete_results.txt\n');
fprintf('  2. one_sample_neonate_by_region.csv\n');
fprintf('  3. one_sample_neonate_by_layer.csv\n');
fprintf('  4. one_sample_neonate_by_region_layer.csv\n');
fprintf('  5. one_sample_neonate_visualization.png\n\n');

%% Helper function for ternary operation
function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end