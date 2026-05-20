% BCAS1 density_mm2 Analysis with Layer - BY morphology
% Linear Mixed-Effects Model: BCAS1_density_mm2 ~ Region*Age*Layer + (1|Slide_number)
% Separate analyses for each morphology type
% Author: [Your Name]
% Date: [Current Date]
% MATLAB Version: 2024b

%% Clear workspace
clear; clc; close all;

%% Load data
data_full = readtable('FigS8_cd.csv');

%% Prepare categorical variables
data_full.Region = categorical(data_full.Region);
data_full.Layer = categorical(data_full.Layer);
data_full.Slide_number = categorical(data_full.Slide_number);
data_full.Age_group = categorical(data_full.Age_group);
data_full.morphology = categorical(data_full.morphology);

%% Get unique morphologies
morphologies = categories(data_full.morphology);

fprintf('========================================\n');
fprintf('BCAS1 DENSITY ANALYSIS BY morphology\n');
fprintf('========================================\n\n');
fprintf('Found %d morphology types:\n', length(morphologies));
for i = 1:length(morphologies)
    fprintf('  %d. %s (n=%d)\n', i, char(morphologies{i}), ...
        sum(data_full.morphology == morphologies{i}));
end
fprintf('\n');

%% Loop through each morphology type
for morph_idx = 1:length(morphologies)
    
    morphology_type = char(morphologies{morph_idx});
    
    fprintf('\n\n');
    fprintf('################################################################\n');
    fprintf('################################################################\n');
    fprintf('###                                                          ###\n');
    fprintf('###   ANALYSIS FOR morphology: %-30s ###\n', upper(morphology_type));
    fprintf('###                                                          ###\n');
    fprintf('################################################################\n');
    fprintf('################################################################\n\n');
    
    %% Filter data for current morphology
    data = data_full(data_full.morphology == morphology_type, :);
    
    %% Display data summary
    fprintf('Dataset Summary for %s:\n', morphology_type);
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
    
    %% Fit Linear Mixed-Effects Model
    fprintf('\nFitting linear mixed-effects model for %s...\n', morphology_type);
    fprintf('Model formula: BCAS1_density_mm2 ~ Region*Age*Layer + (1|Slide_number)\n');
    fprintf('Using REML estimation\n\n');
    
    lme = fitlme(data, 'BCAS1_density_mm2 ~ Region * Age * Layer + (1|Slide_number)', 'FitMethod', 'REML');
    
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
    
    %% PLOT 1: Regions WITHOUT Layer Separation
    fprintf('\nGenerating plot: Regions across age groups (layers combined) for %s...\n', morphology_type);
    
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
                means(j) = mean(group_data.BCAS1_density_mm2);
                sems(j) = std(group_data.BCAS1_density_mm2) / sqrt(height(group_data));
            else
                means(j) = NaN;
                sems(j) = NaN;
            end
        end
        
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
    ylabel('BCAS1 density (cells/mm^2)', 'FontSize', 14, 'FontWeight', 'bold');
    title(sprintf('BCAS1 Density - %s (All Layers)', morphology_type), 'FontSize', 16, 'FontWeight', 'bold');
    legend('Location', 'northwest', 'FontSize', 12);
    grid on;
    box on;
    set(gca, 'FontSize', 12);
    
    filename = sprintf('BCAS1_%s_density_regions_all_layers.png', morphology_type);
    saveas(gcf, filename);
    fprintf('Plot saved as "%s"\n', filename);
    
    %% PLOT 2: Regions Separated by Layer
    fprintf('\nGenerating plots: Regions by layer for %s...\n', morphology_type);
    
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
                    means(j) = mean(group_data.BCAS1_density_mm2);
                    sems(j) = std(group_data.BCAS1_density_mm2) / sqrt(height(group_data));
                else
                    means(j) = NaN;
                    sems(j) = NaN;
                end
            end
            
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
        ylabel('BCAS1 density (cells/mm^2)', 'FontSize', 14, 'FontWeight', 'bold');
        title(sprintf('BCAS1 Density - %s - %s', morphology_type, layer_name), 'FontSize', 16, 'FontWeight', 'bold');
        legend('Location', 'northwest', 'FontSize', 12);
        grid on;
        box on;
        set(gca, 'FontSize', 12);
        
        filename = sprintf('BCAS1_%s_density_%s.png', morphology_type, layer_name);
        saveas(gcf, filename);
        fprintf('Plot for %s saved as "%s"\n', layer_name, filename);
    end
    
    %% Generate Supplemental Table
    fprintf('\n========================================\n');
    fprintf('GENERATING SUPPLEMENTAL TABLE for %s\n', morphology_type);
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
                    mean_val = mean(subset.BCAS1_density_mm2);
                    sem_val = std(subset.BCAS1_density_mm2) / sqrt(height(subset));
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
    stat_test_str = sprintf('Dataset (%s morphology, 0-24 months, n=%d sections):\n', morphology_type, height(data));
    stat_test_str = [stat_test_str, sprintf(['Restricted Maximum Likelihood model (REML) to predict BCAS1 density with ', ...
        'continuous Age (in months), Region (Calc vs. FG vs. CoS), and Layer, ', ...
        'with full three-way interaction, and with random variable of section.\n\n'])];
    
    % Add ANOVA results
    age_idx = find(strcmp(anova_results.Term, 'Age'));
    region_idx = find(strcmp(anova_results.Term, 'Region'));
    layer_idx = find(strcmp(anova_results.Term, 'Layer'));
    region_age_idx = find(strcmp(anova_results.Term, 'Region:Age') | strcmp(anova_results.Term, 'Age:Region'));
    region_layer_idx = find(strcmp(anova_results.Term, 'Region:Layer') | strcmp(anova_results.Term, 'Layer:Region'));
    age_layer_idx = find(strcmp(anova_results.Term, 'Age:Layer') | strcmp(anova_results.Term, 'Layer:Age'));
    
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
    
    %% Perform post-hoc pairwise comparisons based on significant effects
    fprintf('\n========================================\n');
    fprintf('POST-HOC PAIRWISE COMPARISONS for %s\n', morphology_type);
    fprintf('========================================\n');
    fprintf('Only performing post-hoc tests for significant main effects and interactions (p < 0.05)\n\n');
    
    posthoc_results = {};
    
    % Check which effects are significant
    layer_significant = anova_results.pValue(layer_idx) < 0.05;
    region_significant = anova_results.pValue(region_idx) < 0.05;
    age_significant = anova_results.pValue(age_idx) < 0.05;
    region_layer_significant = anova_results.pValue(region_layer_idx) < 0.05;
    region_age_significant = anova_results.pValue(region_age_idx) < 0.05;
    age_layer_significant = anova_results.pValue(age_layer_idx) < 0.05;
    three_way_significant = anova_results.pValue(three_way_idx) < 0.05;
    
    fprintf('Significant effects:\n');
    fprintf('  Main effect of Layer: %s (p=%.4f)\n', ...
        ternary(layer_significant, 'YES', 'NO'), anova_results.pValue(layer_idx));
    fprintf('  Main effect of Region: %s (p=%.4f)\n', ...
        ternary(region_significant, 'YES', 'NO'), anova_results.pValue(region_idx));
    fprintf('  Main effect of Age: %s (p=%.4f)\n', ...
        ternary(age_significant, 'YES', 'NO'), anova_results.pValue(age_idx));
    fprintf('  Region × Layer interaction: %s (p=%.4f)\n', ...
        ternary(region_layer_significant, 'YES', 'NO'), anova_results.pValue(region_layer_idx));
    fprintf('  Region × Age interaction: %s (p=%.4f)\n', ...
        ternary(region_age_significant, 'YES', 'NO'), anova_results.pValue(region_age_idx));
    fprintf('  Age × Layer interaction: %s (p=%.4f)\n', ...
        ternary(age_layer_significant, 'YES', 'NO'), anova_results.pValue(age_layer_idx));
    fprintf('  Region × Age × Layer interaction: %s (p=%.4f)\n\n', ...
        ternary(three_way_significant, 'YES', 'NO'), anova_results.pValue(three_way_idx));
    
    %% POST-HOC TEST 1: Layer main effect (if significant)
    if layer_significant
        fprintf('\n--- POST-HOC: Layer Comparisons (Main Effect) ---\n');
        fprintf('Comparing layers collapsed across regions and age groups\n\n');
        
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
                [h, p] = ttest2(data1.BCAS1_density_mm2, data2.BCAS1_density_mm2);
                
                mean1 = mean(data1.BCAS1_density_mm2);
                mean2 = mean(data2.BCAS1_density_mm2);
                
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
    
    %% POST-HOC TEST 2: Region main effect (if significant)
    if region_significant
        fprintf('\n--- POST-HOC: Region Comparisons (Main Effect) ---\n');
        fprintf('Comparing regions collapsed across layers and age groups\n\n');
        
        region_pairs = {{'Calc', 'CoS'}, {'Calc', 'FG'}, {'CoS', 'FG'}};
        
        for j = 1:length(region_pairs)
            region1 = region_pairs{j}{1};
            region2 = region_pairs{j}{2};
            
            data1 = data(data.Region == region1, :);
            data2 = data(data.Region == region2, :);
            
            if ~isempty(data1) && ~isempty(data2)
                [h, p] = ttest2(data1.BCAS1_density_mm2, data2.BCAS1_density_mm2);
                
                mean1 = mean(data1.BCAS1_density_mm2);
                mean2 = mean(data2.BCAS1_density_mm2);
                
                comparison = sprintf('%s vs. %s', region1, region2);
                
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
        fprintf('\n--- POST-HOC: Region Comparisons ---\n');
        fprintf('Skipped (main effect not significant, p=%.4f)\n', anova_results.pValue(region_idx));
    end
    
    %% POST-HOC TEST 3: Region × Layer interaction (if significant)
    if region_layer_significant
        fprintf('\n--- POST-HOC: Region × Layer Interaction ---\n');
        fprintf('Comparing regions within each layer\n\n');
        
        for layer_idx_loop = 1:length(layers)
            layer_name = char(layers{layer_idx_loop});
            fprintf('\n%s Layer:\n', layer_name);
            
            layer_subset = data(data.Layer == layers{layer_idx_loop}, :);
            
            region_pairs = {{'Calc', 'CoS'}, {'Calc', 'FG'}, {'CoS', 'FG'}};
            
            for j = 1:length(region_pairs)
                region1 = region_pairs{j}{1};
                region2 = region_pairs{j}{2};
                
                data1 = layer_subset(layer_subset.Region == region1, :);
                data2 = layer_subset(layer_subset.Region == region2, :);
                
                if ~isempty(data1) && ~isempty(data2)
                    [h, p] = ttest2(data1.BCAS1_density_mm2, data2.BCAS1_density_mm2);
                    
                    mean1 = mean(data1.BCAS1_density_mm2);
                    mean2 = mean(data2.BCAS1_density_mm2);
                    
                    comparison = sprintf('%s, %s vs. %s, %s', region1, layer_name, region2, layer_name);
                    
                    fprintf('  %s vs. %s: ', region1, region2);
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
        fprintf('\n--- POST-HOC: Region × Layer Interaction ---\n');
        fprintf('Skipped (interaction not significant, p=%.4f)\n', anova_results.pValue(region_layer_idx));
    end
    
    %% POST-HOC TEST 4: Three-way interaction (if significant)
    if three_way_significant
        fprintf('\n--- POST-HOC: Region × Age × Layer Interaction ---\n');
        fprintf('Comparing regions within each age group and layer combination\n\n');
        
        for layer_idx_loop = 1:length(layers)
            layer_name = char(layers{layer_idx_loop});
            
            for i = 1:length(age_groups)
                ag = age_groups{i};
                age_label = age_labels_clean{i};
                
                fprintf('\n%s - %s:\n', layer_name, age_label);
                
                subset = data(data.Age_group == ag & data.Layer == layers{layer_idx_loop}, :);
                
                if isempty(subset)
                    fprintf('  No data\n');
                    continue;
                end
                
                region_pairs = {{'Calc', 'CoS'}, {'Calc', 'FG'}, {'CoS', 'FG'}};
                
                for j = 1:length(region_pairs)
                    region1 = region_pairs{j}{1};
                    region2 = region_pairs{j}{2};
                    
                    data1 = subset(subset.Region == region1, :);
                    data2 = subset(subset.Region == region2, :);
                    
                    if ~isempty(data1) && ~isempty(data2)
                        [h, p] = ttest2(data1.BCAS1_density_mm2, data2.BCAS1_density_mm2);
                        
                        mean1 = mean(data1.BCAS1_density_mm2);
                        mean2 = mean(data2.BCAS1_density_mm2);
                        
                        comparison = sprintf('%s, %s, %s vs. %s, %s, %s', ...
                                           region1, age_label, layer_name, region2, age_label, layer_name);
                        
                        fprintf('  %s vs. %s: ', region1, region2);
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
        end
    else
        fprintf('\n--- POST-HOC: Region × Age × Layer Interaction ---\n');
        fprintf('Skipped (three-way interaction not significant, p=%.4f)\n', anova_results.pValue(three_way_idx));
    end
    
    % Build significance string
    significance_str = sprintf('Post-hoc pairwise comparisons using Student''s t-test (%s morphology):\n', morphology_type);
    significance_str = [significance_str, 'Only performed for significant main effects and interactions (p < 0.05)\n\n'];
    
    if ~isempty(posthoc_results)
        for i = 1:length(posthoc_results)
            significance_str = [significance_str, posthoc_results{i}, '\n'];
        end
        significance_str = [significance_str, '\nAll other comparisons p>0.05'];
    else
        significance_str = [significance_str, 'No significant pairwise comparisons found'];
    end
    
    % Create table structure
    supp_table = table(...
        {sprintf('Fig. S8 (%s)', morphology_type)}, ...
        {sprintf('BCAS1 density (cells/mm²) of %s sections in Calc, CoS, and FG across age groups and layers', morphology_type)}, ...
        {values_str}, ...
        {n_str}, ...
        {stat_test_str}, ...
        {significance_str}, ...
        'VariableNames', {'Supplemental_Fig', 'Measure', 'Values', 'N', 'Statistical_test', 'Significance'});
    
    % Save to CSV
    csv_filename = sprintf('BCAS1_%s_Layer_Supplemental_Table.csv', morphology_type);
    writetable(supp_table, csv_filename);
    fprintf('\nSupplemental table saved to "%s"\n', csv_filename);
    
    % Also save a more readable text version
    txt_filename = sprintf('BCAS1_%s_Layer_Supplemental_Table.txt', morphology_type);
    fid_supp = fopen(txt_filename, 'w');
    fprintf(fid_supp, '========================================================\n');
    fprintf(fid_supp, 'SUPPLEMENTAL TABLE - BCAS1 %s Density Analysis\n', upper(morphology_type));
    fprintf(fid_supp, '========================================================\n\n');
    
    fprintf(fid_supp, 'Figure: Fig. S8 (%s)\n\n', morphology_type);
    
    fprintf(fid_supp, 'Measure:\n');
    fprintf(fid_supp, 'BCAS1 density (cells/mm²) of %s sections in Calc, CoS, and FG across age groups and layers\n\n', morphology_type);
    
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
    
    fprintf('Readable supplemental table saved to "%s"\n', txt_filename);
    
    % Display preview of statistics
    fprintf('\n========================================================\n');
    fprintf('SUPPLEMENTAL TABLE PREVIEW - Statistical Tests (%s)\n', morphology_type);
    fprintf('========================================================\n\n');
    fprintf(stat_test_str);
    
    fprintf('\n========================================\n');
    fprintf('SUPPLEMENTAL TABLE PREVIEW - Post-hoc Comparisons (%s)\n', morphology_type);
    fprintf('========================================\n\n');
    fprintf(significance_str);
    
    fprintf('\n\n=== Outputs complete for %s ===\n', morphology_type);
    fprintf('Files generated:\n');
    fprintf('  1. BCAS1_%s_density_regions_all_layers.png\n', morphology_type);
    num_layers = length(layers);
    for layer_idx = 1:num_layers
        layer_name = char(layers{layer_idx});
        fprintf('  %d. BCAS1_%s_density_%s.png\n', layer_idx+1, morphology_type, layer_name);
    end
    fprintf('  %d. BCAS1_%s_Layer_Supplemental_Table.csv\n', num_layers+2, morphology_type);
    fprintf('  %d. BCAS1_%s_Layer_Supplemental_Table.txt\n\n', num_layers+3, morphology_type);
    
end % End of morphology loop

%% Helper function for ternary operator
function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end

%% Final summary
fprintf('\n\n');
fprintf('################################################################\n');
fprintf('################################################################\n');
fprintf('###                                                          ###\n');
fprintf('###   ALL morphology ANALYSES COMPLETE                      ###\n');
fprintf('###                                                          ###\n');
fprintf('################################################################\n');
fprintf('################################################################\n\n');

fprintf('Summary of analyses:\n');
fprintf('===================\n');
for i = 1:length(morphologies)
    morphology_type = char(morphologies{i});
    n_obs = sum(data_full.morphology == morphologies{i});
    fprintf('  %s: %d observations analyzed\n', morphology_type, n_obs);
end

fprintf('\nAll output files have been saved with morphology-specific prefixes.\n');
fprintf('Check your working directory for:\n');
fprintf('  - PNG plots for each morphology and layer\n');
fprintf('  - CSV supplemental tables for each morphology\n');
fprintf('  - TXT supplemental tables for each morphology\n\n');

fprintf('=== ANALYSIS COMPLETE ===\n\n');