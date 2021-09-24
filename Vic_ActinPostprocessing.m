clear; clc; close all;
xlsfile = readcell('ForActinPostprocessing.xlsx','NumHeaderLines',1); % This is the file contains all the information about the later processing.

NumGroup = size(xlsfile, 1);  % Number of the groups to be calculated.
ExpDate = xlsfile(:, 1);  % The experiment date.
storePath = xlsfile(:, 2);  % Path of the data to be processed.
PAsPath = xlsfile(:, 3);  % Path of the pillar array information.
savePath = xlsfile(:, 4);  % Saving path.
ChannelH = xlsfile(:, 5);  % Channel height (um)
ChannelW = xlsfile(:, 6);  % Channel width (um)
FlowRate = xlsfile(:, 7);  % Flow rate (nL/s)
Init_U = xlsfile(:, 8);  % Initial velocity (m/s)
Obj_Mag = xlsfile(:, 9); % Calibration (um/pixel)
 

for no_Group = 1: NumGroup 
    
    filelist = dir(fullfile(storePath{no_Group},'*.mat'));  % list of the .mat files which contain the reconstruction information (came from 'Filaments detection' code) in one group.
    Info(no_Group).filelist = filelist;
    
    for no_Case = 1:length(filelist)
        
        load([storePath{no_Group}, filesep , filelist(no_Case).name])
        lzero = max(lobject,ceil(5*lnoise));   % This is so important!!!!!!!!!!! Came from when we do the filaments detection.
        
        sorted_lengths = sort(xy.arclen_spl(Good_case));  % Good_case: index of the 'good' cases
        contour_length = mean(sorted_lengths(round(numel(sorted_lengths)/20):end)) * Obj_Mag{no_Group};  % Select the 10% lengest filaments and averaged as the contour length. (UNIT: um)
        Info(no_Group).contour_length(no_Case) = contour_length; 
        Info(no_Group).elastoviscousNum(no_Case) = Get_elastoviscousNum(contour_length*1e-6, Init_U{no_Group});  % Calculate the 'global' elastoviscous number for one trajectory.  (*1e-6: convert the unit to m)
        
        centroidxy = reshape(cell2mat(xy.centroid),2,numel(xy.centroid));
        centroidxy = centroidxy(:, Good_case); 
%         centroidxy = centroidxy + lzero;  % The real CoM in the image!! BUT cannot add lzero here because following 'centroidxy_k' need it (NOT in IMAGE)!!!     
%         Amp(no_Case) = max(centroidxy(2,:)) -  min(centroidxy(2,:));  % This is to calculate the amplitude of the trajectory.
        
        centroidxy_plot_ind = 1;  % Plot -- x axis.
        count = 1;  % for plot
        for no_Goodcas = 1:size(Good_case,2)
            
            if no_Goodcas > 1
                if Good_case(no_Goodcas) - TheLastOne >= 0  % Equal interval sampling. If put 4, it will be 5 and so on.      
                    centroidxy_plot_ind(end+1) = no_Goodcas;
                    
                    crd = xy.crd{1,Good_case(no_Goodcas)};
                    centroidxy_k = centroidxy(:, no_Goodcas);
                    
                    L_ee = sqrt((crd(1,1)-crd(end,1))^2 + (crd(1,2)-crd(end,2))^2) * Obj_Mag{no_Group};  % Calculate the L_ee. (end-to-end distance)
                    Info(no_Group).L_ee_norm{no_Case}(count) = L_ee / contour_length;  % Normalized by the contour length calculated above.  NOTE: Lee/L0 might obviously larger than 1.
                    
                    Gyr = 1/size(crd,1) * [sum((crd(:, 1)-centroidxy_k(1)).^2),  sum((crd(:, 1)-centroidxy_k(1)) .* (crd(:, 2)-centroidxy_k(2)));
                        sum((crd(:, 2)-centroidxy_k(2)) .* (crd(:, 1)-centroidxy_k(1))), sum((crd(:, 2)-centroidxy_k(2)).^2)];
                    
                    [eigenV,eigenD] = eig(Gyr);
                    [d,ind] = sort(diag(eigenD));
                    Ds = eigenD(ind,ind);
                    Vs = eigenV(:,ind);
                    Info(no_Group).Chi{no_Case}(count) = atan(Vs(2,2)/Vs(1,2));
                    Info(no_Group).Chi_norm{no_Case}(count) = atan(Vs(2,2)/Vs(1,2))/pi;
                    
                    
                    Lambda1 = eigenD(2,2); Lambda2 =  eigenD(1,1);
                    Info(no_Group).aniso{no_Case}(count) = 1 - 4*Lambda1*Lambda2/(Lambda1+Lambda2)^2;
                    
                    Info(no_Group).SelectCaseNo{no_Case}(count) = Good_case(no_Goodcas);  % The indexes of the Goodcases. Mostly for the frequency calculation.
                    
                    count = count + 1;
                    TheLastOne = Good_case(no_Goodcas);
                end
                
            else
                crd = xy.crd{1,Good_case(no_Goodcas)};
                centroidxy_k = centroidxy(:, no_Goodcas);
                
                L_ee = sqrt((crd(1,1)-crd(end,1))^2 + (crd(1,2)-crd(end,2))^2) * Obj_Mag{no_Group};  % Calculate the L_ee. (end-to-end distance)
                Info(no_Group).L_ee_norm{no_Case}(count) = L_ee / contour_length;  % Normalized by the contour length calculated above.  NOTE: Lee/L0 might obviously larger than 1.
                
                Gyr = 1/size(crd,1) * [sum((crd(:, 1)-centroidxy_k(1)).^2),  sum((crd(:, 1)-centroidxy_k(1)) .* (crd(:, 2)-centroidxy_k(2)));
                    sum((crd(:, 2)-centroidxy_k(2)) .* (crd(:, 1)-centroidxy_k(1))), sum((crd(:, 2)-centroidxy_k(2)).^2)];
                
                [eigenV,eigenD] = eig(Gyr);
                [d,ind] = sort(diag(eigenD));
                Ds = eigenD(ind,ind);
                Vs = eigenV(:,ind);
                Info(no_Group).Chi{no_Case}(no_Goodcas) = atan(Vs(2,2)/Vs(1,2));
                Info(no_Group).Chi_norm{no_Case}(count) = atan(Vs(2,2)/Vs(1,2))/pi;
                
                Lambda1 = eigenD(2,2); Lambda2 =  eigenD(1,1);
                Info(no_Group).aniso{no_Case}(no_Goodcas) = 1 - 4*Lambda1*Lambda2/(Lambda1+Lambda2)^2;
                
                Info(no_Group).SelectCaseNo{no_Case}(count) = Good_case(no_Goodcas);  % The indexes of the Goodcases. Mostly for the frequency calculation.
                
                count = count + 1;
                TheLastOne = Good_case(no_Goodcas);
            end
        end
        
        Info(no_Group).centroidxy_plotX{no_Case} = centroidxy(1,centroidxy_plot_ind) + lzero;  % lzzero is so important in image plotting!! Namely, when you are drawing based on the raw figure.
        Info(no_Group).centroidxy_plotY{no_Case} = centroidxy(2,centroidxy_plot_ind) + lzero;  % lzzero is so important!!
        
    end
    
end



%% Plot 'L_ee_norm', 'omega' & 'Chi_norm'
% This part is to plot the characterizations along one trajectory.

clearvars -except Info xlsfile
NumGroup = size(xlsfile, 1);  % Number of the groups to be calculated.
ExpDate = xlsfile(:, 1);  % The experiment date.
storePath = xlsfile(:, 2);  % Path of the data to be processed.
PAsPath = xlsfile(:, 3);  % Path of the pillar array information.
savePath = xlsfile(:, 4);  % Saving path.
ChannelH = xlsfile(:, 5);  % Channel height (um)
ChannelW = xlsfile(:, 6);  % Channel width (um)
FlowRate = xlsfile(:, 7);  % Flow rate (nL/s)
Init_U = xlsfile(:, 8);  % Initial velocity (m/s)
Obj_Mag = xlsfile(:, 9); % Calibration (um/pixel)

for no_Group = 1: NumGroup 
    
    filelist = dir(fullfile(storePath{no_Group},'*.mat'));  % list of the .mat files which contain the reconstruction information (came from 'Filaments detection' code) in one group.
    Info(no_Group).filelist = filelist;
    
    for no_Case = 1:length(filelist)
    figure('color', 'w'); set(gcf, 'Position', [100 300 1500 300]);
    
%     yyaxis left  % Plot 'omega'
%     plot(Info(no_Group).centroidxy_plotX{1,no_Case}, Info(no_Group).aniso{1,no_Case}, '--o', 'linewidth', 2);
%     xlim([0 2048]); ylim([0 1]);
%     xlabel('Position (px)','FontSize', 14,'Interpreter', 'latex')
%     ylabel('$\omega = 1 - 4{\lambda}_1{\lambda}_2/({\lambda}_1+{\lambda}_2)^2$','FontSize', 14,'Interpreter', 'latex');
     
    yyaxis left  % Plot 'L_ee_norm'
    plot(Info(no_Group).centroidxy_plotX{1,no_Case}, Info(no_Group).L_ee_norm{1,no_Case}, '--o', 'linewidth', 2);
    xlim([0 2048]); ylim([0 max(Info(no_Group).L_ee_norm{1,no_Case})]);
    ylabel('$L_{ee}/L_0$','FontSize', 14,'Interpreter', 'latex');

    yyaxis right  % Plot 'Chi_norm'
    plot(Info(no_Group).centroidxy_plotX{1,no_Case}, Info(no_Group).Chi_norm{1,no_Case}, '--o', 'linewidth', 2);
    xlim([0 2048]); ylim([-0.5 0.5]);
    ylabel('${\chi} / {\pi}$','FontSize', 14,'Interpreter', 'latex');
    line([0,2048],[0,0],'LineStyle','--','Color',[0.8500 0.3250 0.0980],'LineWidth',0.2);  
    
    % This is to calculate the average positions of the pillars.
    [ave_PA_Ra, pillar_column, ~] = Get_PAsInfo(PAsPath{no_Group});

    % The centers of the pillars
    for n_centers = 1:numel(pillar_column)
        if mod(n_centers, 2) == 0
            line([pillar_column(n_centers), pillar_column(n_centers)],[-0.5,0.5],...
                'Color','r','LineWidth',0.5);
        else
            line([pillar_column(n_centers), pillar_column(n_centers)],[-0.5,0.5],...
                'Color','c','LineWidth',0.5);  % Draw the positions of the circle's center
        end
    end
    
    % The edges of the pillars
    for n_centers = 1:numel(pillar_column)
        if mod(n_centers, 2) == 0
            line([pillar_column(n_centers)-ave_PA_Ra, pillar_column(n_centers)-ave_PA_Ra],...
                [-0.5,0.5],'LineStyle',':','Color','r','LineWidth',0.3);
            line([pillar_column(n_centers)+ave_PA_Ra, pillar_column(n_centers)+ave_PA_Ra],...
                [-0.5,0.5],'LineStyle',':','Color','r','LineWidth',0.3);
        else
            line([pillar_column(n_centers)-ave_PA_Ra, pillar_column(n_centers)-ave_PA_Ra],...
                [-0.5,0.5],'LineStyle',':','Color','c','LineWidth',0.3);
            line([pillar_column(n_centers)+ave_PA_Ra, pillar_column(n_centers)+ave_PA_Ra],...
                [-0.5,0.5],'LineStyle',':','Color','c','LineWidth',0.3);  % Draw the positions of the circle's edges.
        end
    end
    
%     export_fig([savePath{no_Group},filesep,Info(no_Group).filelist(no_Case).name,'_Lee_Chi_Position'],'-tif')
%     savefig([savePath{no_Group},filesep,Info(no_Group).filelist(no_Case).name,'_Lee_Chi_Position.fig'])

    end
end



%% Plot 'L_ee_norm', 'omega' & 'Chi_norm' in cell;
% This part is to plot the characterizations in one cell.

clearvars -except Info xlsfile
NumGroup = size(xlsfile, 1);  % Number of the groups to be calculated.
ExpDate = xlsfile(:, 1);  % The experiment date.
storePath = xlsfile(:, 2);  % Path of the data to be processed.
PAsPath = xlsfile(:, 3);  % Path of the pillar array information.
savePath = xlsfile(:, 4);  % Saving path.
ChannelH = xlsfile(:, 5);  % Channel height (um)
ChannelW = xlsfile(:, 6);  % Channel width (um)
FlowRate = xlsfile(:, 7);  % Flow rate (nL/s)
Init_U = xlsfile(:, 8);  % Initial velocity (m/s)
Obj_Mag = xlsfile(:, 9); % Calibration (um/pixel)


for no_Group = 1: NumGroup
    
    % This is to calculate the average positions of the pillars.
    [~, pillar_column, ~] = Get_PAsInfo(PAsPath{no_Group});
    DD = mean(diff(pillar_column));   % the distance betweeen two columns
    pillar_column_add = [pillar_column(1)-DD, pillar_column];
    
    figure('color', 'w'); set(gcf, 'Position', [100 300 1500 300]);
    filelist = dir(fullfile(storePath{no_Group},'*.mat'));  % list of the .mat files which contain the reconstruction information (came from 'Filaments detection' code) in one group.
    Info(no_Group).filelist = filelist;
    
    for no_Case = 1:length(filelist)
        
        %     figure('color', 'w'); set(gcf, 'Position', [100 300 1500 300]);
%         if Info(no_Group).contour_length(no_Case)>10; continue; end
%         if minRa(no_Case)<11.4050; continue; end    % The 'minRa' comes from the code 'Vic_Compare_Streamlines_to_Simulation.m'. To be continued...
        
%         for kk = 1:2:numel(pillar_column_add)-2  % every two columns
        for kk = 1:numel(pillar_column_add)-1  % every column
%             tmp_ind = Info(no_Group).centroidxy_plotX{1,no_Case} >= pillar_column_add(kk) & Info(no_Group).centroidxy_plotX{1,no_Case} <= pillar_column_add(kk+2);  % every two columns
            tmp_ind = Info(no_Group).centroidxy_plotX{1,no_Case} >= pillar_column_add(kk) & Info(no_Group).centroidxy_plotX{1,no_Case} <= pillar_column_add(kk+1);  % every column
            
%             yyaxis left
% %             plot((Info(no_Group).centroidxy_plotX{1,no_Case}(tmp_ind)-pillar_column_add(kk))/mean(diff(pillar_column_add))/2, Info(no_Group).aniso{1,no_Case}(tmp_ind),'marker','*','LineStyle', 'none'); hold on    % every two columns
%             plot((Info(no_Group).centroidxy_plotX{1,no_Case}(tmp_ind)-pillar_column_add(kk))/mean(diff(pillar_column_add)), Info(no_Group).aniso{1,no_Case}(tmp_ind),'marker','*','LineStyle', 'none'); hold on  % every column
%             xlabel('$Position$','FontSize', 14,'Interpreter', 'latex')
%             ylabel('$\omega = 1 - 4{\lambda}_1{\lambda}_2/({\lambda}_1+{\lambda}_2)^2$','FontSize', 14,'Interpreter', 'latex');
            
            yyaxis left
%             plot((Info(no_Group).centroidxy_plotX{1,no_Case}(tmp_ind)-pillar_column_add(kk))/mean(diff(pillar_column_add))/2, Info(no_Group).L_ee_norm{1,no_Case}(tmp_ind),'marker','*','LineStyle', 'none'); hold on    % every two columns
            plot((Info(no_Group).centroidxy_plotX{1,no_Case}(tmp_ind)-pillar_column_add(kk))/mean(diff(pillar_column_add)), Info(no_Group).L_ee_norm{1,no_Case}(tmp_ind),'marker','*','LineStyle', 'none'); hold on  % every column
            xlabel('$Position$','FontSize', 14,'Interpreter', 'latex') 
            ylabel('$L_{ee}/L_0$','FontSize', 14,'Interpreter', 'latex');
            
            yyaxis right
%             plot((Info(no_Group).centroidxy_plotX{1,no_Case}(tmp_ind)-pillar_column_add(kk))/mean(diff(pillar_column_add))/2, Info(no_Group).Chi_norm{1,no_Case}(tmp_ind),'marker','o','LineStyle', 'none');hold on    % every two columns
            plot((Info(no_Group).centroidxy_plotX{1,no_Case}(tmp_ind)-pillar_column_add(kk))/mean(diff(pillar_column_add)), Info(no_Group).Chi_norm{1,no_Case}(tmp_ind),'marker','o','LineStyle', 'none');hold on  % every column
            xlim([0 1]);
            ylabel('${\chi} / {\pi}$','FontSize', 14,'Interpreter', 'latex');
            
        end
        title('$Deformation\ of\ the\ filaments\ in\ half\ period$','FontSize', 18,'Interpreter', 'latex')
        
%         export_fig([savePath{no_Group},filesep,'Deformation_of_the_Filaments_every_column_',datestr(ExpDate{no_Group}),'-',num2str(no_Group)],'-tif')
%         savefig([savePath{no_Group},filesep,'Deformation_of_the_Filaments_every_column_',datestr(ExpDate{no_Group}),'-',num2str(no_Group),'.fig'
    end
end



%% Plot elastoviscousNum vs. L_ee_morm
% This part is used to polt the elasto-viscous number /mu vs. end-to-end
% length L_ee_norm.

clearvars -except Info xlsfile
NumGroup = size(xlsfile, 1);  % Number of the groups to be calculated.
ExpDate = xlsfile(:, 1);  % The experiment date.
storePath = xlsfile(:, 2);  % Path of the data to be processed.
PAsPath = xlsfile(:, 3);  % Path of the pillar array information.
savePath = xlsfile(:, 4);  % Saving path.
ChannelH = xlsfile(:, 5);  % Channel height (um)
ChannelW = xlsfile(:, 6);  % Channel width (um)
FlowRate = xlsfile(:, 7);  % Flow rate (nL/s)
Init_U = xlsfile(:, 8);  % Initial velocity (m/s)
Obj_Mag = xlsfile(:, 9); % Calibration (um/pixel)

plot_counter1 = 1; counter1 = 1;  % plot_counter1: for the final plot. 
for no_Group = 1: NumGroup  
    
    for no_Case = 1:length(Info(no_Group).filelist)
        
        tmp_L_ee_norm = Info(no_Group).L_ee_norm{1, no_Case};  % The L_ee_norm for one trajectory.
         
        [values,BinEdges] = histcounts(tmp_L_ee_norm, 10);  % Histogram bin counts. The number of bins is 10.
        tmp_ind = find(values==max(values));  % The maximum after histogram.
        if numel(tmp_ind) > 1  % The cases which don't only have one maximum value.
            MultiMaxCases{counter1} = Info(no_Group).filelist(no_Case).name;
            counter1 = counter1 + 1;
        end
        L_ee_plot(plot_counter1) = (BinEdges(tmp_ind(1)+1) + BinEdges(tmp_ind(1)))/2;  % Most probable L_ee_norm.
%         L_ee_plot(plot_counter1) = (BinEdges(1) + BinEdges(2))/2;  % Minimum L_ee_norm.
        mu_0_plot(plot_counter1) = Info(no_Group).elastoviscousNum(no_Case);  % The elasto viscous number.
        plot_counter1 = plot_counter1 + 1;
        
    end
end

figure('color', 'w'); set(gcf, 'Position', [100 300 1000 500]);
semilogx(mu_0_plot, L_ee_plot, 'b*')
% title('$CoM\ Distribution$','FontSize', 18,'Interpreter', 'latex')
xlabel('$\mu_0$','FontSize', 18,'Interpreter', 'latex');
ylabel('$L_{ee}/L_0$','FontSize', 18,'Interpreter', 'latex');
% axis equal;
% xlim([0 2]);  ylim([0 1]);
% export_fig([savePath{no_Group},filesep,'mostprob_Lee_vs_mu0_',datestr(ExpDate{no_Group}),'-',num2str(no_Group)],'-tif')
% savefig([savePath{no_Group},filesep,'mostprob_Lee_vs_mu0_',datestr(ExpDate{no_Group}),'-',num2str(no_Group),'.fig'])



%%  Plot elastoviscousNum vs. L_ee_morm
% Draw Lee/L0 vs mu0, meanwhile divide into different parts according to
% the initial position.



%% Plot pdf of CoM
% This part is used to polt the pdf of CoM in a cell.

clearvars -except Info xlsfile
NumGroup = size(xlsfile, 1);  % Number of the groups to be calculated.
ExpDate = xlsfile(:, 1);  % The experiment date.
storePath = xlsfile(:, 2);  % Path of the data to be processed.
PAsPath = xlsfile(:, 3);  % Path of the pillar array information.
savePath = xlsfile(:, 4);  % Saving path.
ChannelH = xlsfile(:, 5);  % Channel height (um)
ChannelW = xlsfile(:, 6);  % Channel width (um)
FlowRate = xlsfile(:, 7);  % Flow rate (nL/s)
Init_U = xlsfile(:, 8);  % Initial velocity (m/s)
Obj_Mag = xlsfile(:, 9); % Calibration (um/pixel)

for no_Group = 1: NumGroup
    
    filelist = dir(fullfile(storePath{no_Group},'*.mat'));  % list of the .mat files which contain the reconstruction information (came from 'Filaments detection' code) in one group.
    % This is to calculate the average positions of the pillars.
    [ave_PA_Ra, pillar_column, pillar_row] = Get_PAsInfo(PAsPath{no_Group});
    DD = mean(diff(pillar_column));   % the distance betweeen two columns
    pillar_column_add = [pillar_column(1)-DD, pillar_column];
    Y_shift =  2048-pillar_row(end);   % shift the plot up or down to make it in a 'cell'. Need to be flipped and 2048 is the size of the image.
    
    for no_Case = 1:length(filelist)    % choose the cases to draw
        for kk = 1:2:numel(pillar_column_add)-2   % every two columns. 
            tmp_ind = Info(no_Group).centroidxy_plotX{1,no_Case} >= pillar_column_add(kk) & Info(no_Group).centroidxy_plotX{1,no_Case} <= pillar_column_add(kk+2);  % every two columns.
            scatter1 = scatter((Info(no_Group).centroidxy_plotX{1,no_Case}(tmp_ind)-pillar_column_add(kk))/DD, (mod(Info(no_Group).centroidxy_plotY{1,no_Case}(tmp_ind)-Y_shift,DD))/DD,'filled', 'b');
            alpha(scatter1,0.2);  hold on
            hold on;
        end
    end
    
    clearvars pillar_column_add pillar_column pillar_row
    
end

figure('color', 'w'); %set(gcf, 'Position', [100 300 1000 500]);
title('$CoM\ Distribution$','FontSize', 18,'Interpreter', 'latex')
viscircles([1,0; 1,1; 0,0.5; 2,0.5],[ave_PA_Ra/DD; ave_PA_Ra/DD; ave_PA_Ra/DD; ave_PA_Ra/DD]);  % plot the pillar array according to the layout.
xlabel('$x/D_{C2C}$','FontSize', 18,'Interpreter', 'latex');
ylabel('$y/D_{C2C}$','FontSize', 18,'Interpreter', 'latex');
axis equal;
xlim([0 2]);  ylim([0 1]);
% export_fig(['F:\PhD, PMMH, ESPCI\Processing\20210430-Actin\results\Figures\CoM_1nL'],'-tif')
% export_fig([savePath{no_Group},filesep,'CoM_',datestr(ExpDate{no_Group}),'-',num2str(no_Group)],'-tif')
% savefig([savePath{no_Group},filesep,'CoM_',datestr(ExpDate{no_Group}),'-',num2str(no_Group),'.fig'])



%% 
% Draw Lee/L0 vs mu0, meanwhile divide into different parts according to
% the initial position.



%% About the periodicity (Orientation & Deformation)

clearvars -except Info xlsfile
NumGroup = size(xlsfile, 1);  % Number of the groups to be calculated.
ExpDate = xlsfile(:, 1);  % The experiment date.
storePath = xlsfile(:, 2);  % Path of the data to be processed.
PAsPath = xlsfile(:, 3);  % Path of the pillar array information.
savePath = xlsfile(:, 4);  % Saving path.
ChannelH = xlsfile(:, 5);  % Channel height (um)
ChannelW = xlsfile(:, 6);  % Channel width (um)
FlowRate = xlsfile(:, 7);  % Flow rate (nL/s)
Init_U = xlsfile(:, 8);  % Initial velocity (m/s)
Obj_Mag = xlsfile(:, 9); % Calibration (um/pixel)

The_GAP = 3e-5; % The c2c distance between pillars.
plot_counter1 = 1;
for no_Group = 1: NumGroup
    
    filelist = dir(fullfile(storePath{no_Group},'*.mat'));  % list of the .mat files which contain the reconstruction information (came from 'Filaments detection' code) in one group.
    for no_Case = 1:length(filelist)    % choose the cases to draw
        [pxx,f] = plomb(Info(no_Group).Chi_norm{1, no_Case}, Info(no_Group).SelectCaseNo{1, no_Case},'power'); % Chi_norm
        [pxx1,f1] = plomb(Info(no_Group).L_ee_norm{1, no_Case}, Info(no_Group).SelectCaseNo{1, no_Case},'power'); % L_ee_norm
%         figure; plomb(Info(no_Group).L_ee_norm{1, no_Case}, Info(no_Group).SelectCaseNo{1, no_Case},'power');
        TMP = diff(Info(no_Group).Chi_norm{1, no_Case});
        if min(cos(TMP)) < 0.9  % Select the smooth cases.
            %         figure; plot(Info(no_Group).Chi_norm{1, no_Case});
            %         figure; plot(cos(TMP)); ylim([0.5 1]);
            Period_plot(plot_counter1) = 0;
            Period_plot1(plot_counter1) = 0;
        else
            %         figure; plot(pxx, f);
            [pk,f0] = findpeaks(pxx,f); % Chi_norm
            [pk1,f01] = findpeaks(pxx1,f1); % L_ee_norm
            if  isempty(f0)
                Period_plot(plot_counter1) = 0;  % Chi_norm
                Period_plot1(plot_counter1) = 0;   % L_ee_norm
            else
% % %                 figure('color', 'w'); set(gcf, 'Position', [100 300 1000 500]);
% % %                 plot(Info(no_Group).SelectCaseNo{1, no_Case}, Info(no_Group).Chi_norm{1, no_Case});set(gca,'FontSize',12)
% % %                 xlabel('$Time\ (frame)$','FontSize', 18,'Interpreter', 'latex');
% % %                 ylabel('${\chi} / {\pi}$','FontSize', 18,'Interpreter', 'latex');
% % % %                 export_fig([savePath{no_Group},filesep,'Orientation_vs_Position_',datestr(ExpDate{no_Group}),'-',num2str(no_Group)],'-tif')
% % %                 
% % %                 figure('color', 'w'); set(gcf, 'Position', [100 300 600 500]);
% % %                 plomb(Info(no_Group).Chi_norm{1, no_Case}, Info(no_Group).SelectCaseNo{1, no_Case},'power');set(gca,'FontSize',12)
% % % %                 export_fig([savePath{no_Group},filesep,'PSD_vs_Frequency_',datestr(ExpDate{no_Group}),'-',num2str(no_Group)],'-tif')
% % %                 
% % %                 figure('color', 'w'); set(gcf, 'Position', [100 300 600 500]);
% % %                 plot(f, pxx, f0, pk,'ro'); set(gca,'FontSize',12)
% % %                 xlabel('$Frequency\ (Hz)$','FontSize', 18,'Interpreter', 'latex');
% % %                 ylabel('$Power\ Spectral\ Density\ (PSD)$','FontSize', 18,'Interpreter', 'latex');
%                 export_fig([savePath{no_Group},filesep,'PSD_vs_Frequency2_',datestr(ExpDate{no_Group}),'-',num2str(no_Group)],'-tif')


                Period_plot(plot_counter1) = 1/f0(pk == max(pk)) * 0.02 * Init_U{no_Group, 1} / The_GAP; % Chi_norm.    Normalized  by the initial velocity and the c2c distanse between two pillars.
                Period_plot1(plot_counter1) = 1/f01(pk1 == max(pk1)) * 0.02 * Init_U{no_Group, 1} / The_GAP; % L_ee_norm
%                 if 1/f0(pk == max(pk)) > 90
%                     disp(Info(no_Group).filelist(no_Case).name)
%                 end
            end
        end
        mu_0_plot(plot_counter1) = Info(no_Group).elastoviscousNum(no_Case);  % The elasto viscous number.
        plot_counter1 = plot_counter1 + 1;
    end
    
end


PLOT = [mu_0_plot; Period_plot; Period_plot1];
PLOT(:,PLOT(2,:)==0)=[];
figure('color', 'w'); set(gcf, 'Position', [100 300 1000 500]);
semilogx(PLOT(1,:), PLOT(2,:), 'b*', 'MarkerSize', 10); hold on
% semilogx(PLOT(1,:), PLOT(3,:), 'ro', 'MarkerSize', 10); hold on
% legend('$\chi$','FontSize', 18,'Interpreter', 'latex');


% semilogx(mu_0_plot, Period_plot, 'b*', 'MarkerSize', 10); hold on
% semilogx(mu_0_plot, Period_plot1, 'ro', 'MarkerSize', 10); hold on
set(gca,'FontSize',12)
% title('$CoM\ Distribution$','FontSize', 18,'Interpreter', 'latex')
xlabel('$\mu_0$','FontSize', 18,'Interpreter', 'latex');
ylabel('$U_0/(\lambda{a} \times f_p)$','FontSize', 18,'Interpreter', 'latex');
% axis equal;
% xlim([0 2]);  
line([100 1e6], [1 1],'Color','red','LineStyle','--')
% legend('$\chi$','','FontSize', 18,'Interpreter', 'latex');
% ylim([0.4 1.4]);
% export_fig([savePath{no_Group},filesep,'Orientation_periodicity_vs_mu0_',datestr(ExpDate{no_Group}),'-',num2str(no_Group)],'-tif')
% savefig([savePath{no_Group},filesep,'mostprob_Lee_vs_mu0_',datestr(ExpDate{no_Group}),'-',num2str(no_Group),'.fig'])


%% Function to calculate the mu_0
function mu_0 = Get_elastoviscousNum(L, u_0)
% This is to calculate the elasto-viscous number

B = 6.9e-26;  % Bending rigidity
a = 2e-5;  % Diameter of the pillar
mu = 6.1e-3;  % Dynalic viscosity
d = 8e-9; % Diameter of the actin filament

mu_0 = 8 * pi * mu * L^4 * u_0 / (B * a * -log((d/L)^2 * exp(1)));

end



%% Function for pillar array information.
function [PA_Ra, PA_cl, PA_rw] = Get_PAsInfo(PAs)
% To extract the pillar columns and rows.
% PAs: the path of the PAs results got from the 'Circle Finder' APP.
% Including variables 'centers', 'circleMask', 'metric', and 'radii'.

load(PAs);  % Load the PAs information.
PA_Ra = mean(radii);  % The averaged the radius.
sorted_centers = sort(centers(:,1));  % Calculate the interval along x-direction.
Jumps = find(diff(sorted_centers) > 100); Jumps = [0;Jumps;size(sorted_centers,1)];  % Please change the value '100' accordingly.
for ii = 1:size(Jumps, 1)-1
    PA_cl(ii) = mean(sorted_centers(Jumps(ii)+1: Jumps(ii + 1)));
end

sorted_centersY = sort(centers(:,2));  % Calculate the interval along y-direction.
JumpsY = find(diff(sorted_centersY) > 80); JumpsY = [0;JumpsY;size(sorted_centersY,1)];   % Please change the value '80' accordingly.
for ii = 1:size(JumpsY, 1)-1
    PA_rw(ii) = mean(sorted_centersY(JumpsY(ii)+1: JumpsY(ii + 1)));
end

end


    
    
    
    
