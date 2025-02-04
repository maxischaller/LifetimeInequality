function [] = paramdisp(paramhat,hessian,calib)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Display estimated parameters of life-cycle model %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 0. Unpack model elements:
% ----------------------------------

    M = calib.M;  


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 1. Derivation of standard errors:
% ----------------------------------

%%% Calculate elements for standard errors
    ihess = inv(hessian);
    ste   = sqrt(diag(ihess));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 2. Table 1: Estimated parameters
% ----------------------------------    

%%% Extract estimated parameters
    theta_w    = paramhat(   1:M+ 9,1);
    theta_u    = paramhat(M+10:M+14,1);
    phi_o      = paramhat(M+15:M+20,1);
    theta_m    = paramhat(M+21:M+22,1);
    inter      = [0; paramhat(M+23:M+32,1)];

%%% Derive Type-3 Probability and standard error
    p3      = 1 - theta_m(1,1) - theta_m(2,1);
    p3_ste  = sqrt((-ones(2,1))'*ihess(1+M+20:2+M+20,1+M+20:2+M+20)*(-ones(2,1)));


%%% Print Table 1 to Command Window
    disp(' ');
    disp('--------------------------------------------------------------------------------------------------');
    disp('--------------------------------------------------------------------------------------------------');
    disp('     Table 1: Parameters of the utility function, wage equation and type probabilities            ');
    disp('--------------------------------------------------------------------------------------------------');
    disp('                                                                Estimate           St.E.          ');
    disp('--------------------------------------------------------------------------------------------------');
    disp('Panel I: Utility function:');
    disp(' ');
    disp(['Alpha_1:  Weight on utility from consumption and leisure         '   num2str(round(   theta_u(1,1)    *1000)/1000) '             '     num2str(round(ste(    M+10,1)  *10000)/10000)]);
    disp(['Alpha_21: Disutility of employment, bad health                   '   num2str(round(   theta_u(2,1)    *1000)/1000) '             '     num2str(round(ste(    M+11,1)  *10000)/10000)]);
    disp(['Alpha_22: Disutility of employment, good health                  '   num2str(round(   theta_u(3,1)    *1000)/1000) '             '     num2str(round(ste(    M+12,1)  *10000)/10000)]);
    disp(['Alpha_31: Disutility of unemployment, bad health                 '   num2str(round(   theta_u(4,1)    *1000)/1000) '             '     num2str(round(ste(    M+13,1)  *10000)/10000)]);
    disp(['Alpha_32: Disutility of unemployment, good health                '   num2str(round(   theta_u(5,1)    *1000)/1000) '             '     num2str(round(ste(    M+14,1)  *10000)/10000)]);
    disp('--------------------------------------------------------------------------------------------------');    
    disp('Panel II: Wage equation');
    disp(' ');
    disp(['Intercept for productive ability type H                          '   num2str(round(   theta_w(1,1)    *1000)/1000) '             '     num2str(round(ste(1        ,1)  *10000)/10000)]);
    disp(['Intercept for productive ability type M                          '   num2str(round(   theta_w(2,1)    *1000)/1000) '             '     num2str(round(ste(2        ,1)  *10000)/10000)]);
    disp(['Intercept for productive ability type L                          '   num2str(round(   theta_w(3,1)    *1000)/1000) '             '     num2str(round(ste(3        ,1)  *10000)/10000)]);
    disp(['Years of education/10                                            '   num2str(round(   theta_w(  M+2,1)*1000)/1000) '             '     num2str(round(ste(     M+ 2,1)  *10000)/10000)]);
    disp(['Experience/10, low education                                     '   num2str(round(   theta_w(  M+3,1)*1000)/1000) '             '     num2str(round(ste(     M+ 3,1)  *10000)/10000)]);
    disp(['Experience/10, high education                                    '   num2str(round(   theta_w(  M+4,1)*1000)/1000) '             '     num2str(round(ste(     M+ 4,1)  *10000)/10000)]);
    disp(['Experience^2/1000, low education                                 '   num2str(round(   theta_w(  M+5,1)*1000)/1000) '             '     num2str(round(ste(     M+ 5,1)  *10000)/10000)]);
    disp(['Experience^2/1000, high education                                '   num2str(round(   theta_w(  M+6,1)*1000)/1000) '             '     num2str(round(ste(     M+ 6,1)  *10000)/10000)]);    
    disp(['Good health                                                      '   num2str(round(   theta_w(  M+7,1)*1000)/1000) '             '     num2str(round(ste(     M+ 7,1)  *10000)/10000)]);
    disp(['Autocorrelation of wage shocks                                   '   num2str(round(   theta_w(  M+1,1)*1000)/1000) '             '     num2str(round(ste(     M+ 1,1)  *10000)/10000)]);
    disp(['St.d. of wage shocks                                             '   num2str(round(   theta_w(  M+8,1)*1000)/1000) '             '     num2str(round(ste(     M+ 8,1)  *10000)/10000)]);
    disp(['St.d. of wage measurement error                                  '   num2str(round(   theta_w(  M+9,1)*1000)/1000) '             '     num2str(round(ste(     M+ 9,1)  *10000)/10000)]);
    disp('--------------------------------------------------------------------------------------------------');
    disp('Panel III: Productive ability type probabilities');
    disp(' ');
    disp(['Probability of productive ability type H                         '   num2str(round(theta_m(1,1)       *1000)/1000) '             '     num2str(round(ste(1+  M+20,1)  *10000)/10000)]);
    disp(['Probability of productive ability type M                         '   num2str(round(theta_m(2,1)       *1000)/1000) '             '     num2str(round(ste(2+  M+20,1)  *10000)/10000)]);
    disp(['Probability of productive ability type L                         '   num2str(round(    p3             *1000)/1000) '             '     num2str(round(p3_ste           *10000)/10000)]);
    disp('--------------------------------------------------------------------------------------------------');
    disp('Panel IV: Systematic education cost components');
    disp(' ');
    disp([' 8 years of education                                            '   num2str(round(   inter( 1,1)     *1000)/1000) '             '                                                   ]);
    disp([' 9 years of education                                            '   num2str(round(   inter( 2,1)     *1000)/1000) '             '      num2str(round(ste(    M+23,1)  *10000)/10000)]);
    disp(['10 years of education                                            '   num2str(round(   inter( 3,1)     *1000)/1000) '             '      num2str(round(ste(    M+24,1)  *10000)/10000)]);
    disp(['11 years of education                                            '   num2str(round(   inter( 4,1)     *1000)/1000) '             '      num2str(round(ste(    M+25,1)  *10000)/10000)]);
    disp(['12 years of education                                            '   num2str(round(   inter( 5,1)     *1000)/1000) '             '      num2str(round(ste(    M+26,1)  *10000)/10000)]);
    disp(['13 years of education                                            '   num2str(round(   inter( 6,1)     *1000)/1000) '             '      num2str(round(ste(    M+27,1)  *10000)/10000)]);
    disp(['14 years of education                                            '   num2str(round(   inter( 7,1)     *1000)/1000) '             '      num2str(round(ste(    M+28,1)  *10000)/10000)]);
    disp(['15 years of education                                            '   num2str(round(   inter( 8,1)     *1000)/1000) '             '      num2str(round(ste(    M+29,1)  *10000)/10000)]);
    disp(['16 years of education                                            '   num2str(round(   inter( 9,1)     *1000)/1000) '             '      num2str(round(ste(    M+30,1)  *10000)/10000)]);
    disp(['17 years of education                                            '   num2str(round(   inter(10,1)     *1000)/1000) '             '      num2str(round(ste(    M+31,1)  *10000)/10000)]);
    disp(['18 years of education                                            '   num2str(round(   inter(11,1)     *1000)/1000) '             '      num2str(round(ste(    M+32,1)  *10000)/10000)]);
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 3. Table SWA.3 - Panel 1: Parameter estimates - Job offers
% ------------------------------------------------------------
    disp(' ');
    disp('--------------------------------------------------------------------------------------------------');
    disp('--------------------------------------------------------------------------------------------------');
    disp('                   Table SWA.3: Parameters estimates - employment risks                           ');
    disp('--------------------------------------------------------------------------------------------------');
    disp('                                                                Estimate           St.E.          ');
    disp('--------------------------------------------------------------------------------------------------');    
    disp('Panel I: Job offers');
    disp(' ');
    disp(['Intercept:                                                       '    num2str(round(   phi_o(1,1)     *1000)/1000) '             '    num2str(round(ste(    M+15,1)  *10000)/10000)]);
    disp(['High eduation:                                                   '    num2str(round(   phi_o(2,1)     *1000)/1000) '             '    num2str(round(ste(    M+16,1)  *10000)/10000)]);
    disp(['Good health:                                                     '    num2str(round(   phi_o(3,1)     *1000)/1000) '             '    num2str(round(ste(    M+17,1)  *10000)/10000)]);
    disp(['Age>=50:                                                         '    num2str(round(   phi_o(4,1)     *1000)/1000) '             '    num2str(round(ste(    M+18,1)  *10000)/10000)]);
    disp(['Age>=55:                                                         '    num2str(round(   phi_o(5,1)     *1000)/1000) '             '    num2str(round(ste(    M+19,1)  *10000)/10000)]);
    disp(['Age>=60:                                                         '    num2str(round(   phi_o(6,1)     *1000)/1000) '             '    num2str(round(ste(    M+20,1)  *10000)/10000)]);
    disp('--------------------------------------------------------------------------------------------------');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 4. Table 3: Job offer and involutary job separation probabilities
% ------------------------------------------------------------------
    [s,o] = offsep(phi_o,calib);

    [s_ste,o_ste] = osdelta(phi_o,hessian,calib);

    disp('--------------------------------------------------------------------------------------------------');
    disp('--------------------------------------------------------------------------------------------------');
    disp('                        TABLE 3: Job offer and involutary job separation probabilities             ');
    disp('--------------------------------------------------------------------------------------------------');
    disp(' ');
    disp('--------------------------------------------------------------------------------------------------');
    disp('                      Panel I: Job offer probabilities                                            ')
    disp('--------------------------------------------------------------------------------------------------');      
    disp('Job offers - Low education:');
    disp(' ');
    disp([o(1,:,1,11)' o(1,:,1,31)' o(1,:,1,36)' o(1,:,1,41)']);
    disp('Job offers - High education:');
    disp(' ');    
    disp([o(3,:,1,11)' o(3,:,1,31)' o(3,:,1,36)' o(3,:,1,41)']);
    disp('Job offers: Standard errors:');
    disp(' ');  
    disp([o_ste(1,:,1,11)' o_ste(1,:,1,31)' o_ste(1,:,1,36)' o_ste(1,:,1,41)'
        o_ste(3,:,1,11)' o_ste(3,:,1,31)' o_ste(3,:,1,36)' o_ste(3,:,1,41)']);
    disp(' ');      
    disp('--------------------------------------------------------------------------------------------------');
    disp('                      Panel II: Involuntary job separation probabilities                          ')
    disp('--------------------------------------------------------------------------------------------------');      
    disp('Job separations: Low education');
    disp(' ');
    disp([s(1,:,1,11)' s(1,:,1,31)' s(1,:,1,36)' s(1,:,1,41)']);
    disp('Job separations: High education');
    disp(' ');    
    disp([s(3,:,1,11)' s(3,:,1,31)' s(3,:,1,36)' s(3,:,1,41)']);
    disp('Job separations: Standard errors:');
    disp(' ');
    disp([s_ste(1,:,1,11)' s_ste(1,:,1,31)' s_ste(1,:,1,36)' s_ste(1,:,1,41)'
        s_ste(3,:,1,11)' s_ste(3,:,1,31)' s_ste(3,:,1,36)' s_ste(3,:,1,41)']);
    disp('--------------------------------------------------------------------------------------------------');
    disp('--------------------------------------------------------------------------------------------------');
    disp(' ');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 5. Export Results
% ------------------------------------------------------------------
%   > only after execution of estimation for the main specification

    if calib.switch_estimexport == 1
        disp('Exporting estimation results...')
        % --------------------------------------------------------------------
        %%% Table 1: Parameters of the utility function, wage equation and type probabilities
            % >>> Panel I: Utility function
            %paramout_util = round(theta_u*1000)/1000;  % if desired to round on output
            %export (note round param 1,000, round ste 10,000)
            paramout_util = [theta_u,ste(M+10:M+14,1)];
                %table(paramout_util)
                writetable(table(paramout_util),join([calib.tableout,'CollectedResults.xlsx']),'Sheet','Tab_1_KeyParams','Range','B5','WriteVariableNames',false,'AutoFitWidth',false);
    
            % >>> Panel II: Wage equation
            paramout_wage = [theta_w(1:3,1),ste(1:3,1); ...
                             theta_w(M+2:M+7,1), ste(M+2:M+7,1); ...
                             theta_w(M+1,1), ste(M+1,1); ...
                             theta_w(M+8:M+9,1), ste(M+8:M+9,1)];
                writetable(table(paramout_wage),join([calib.tableout,'CollectedResults.xlsx']),'Sheet','Tab_1_KeyParams','Range','B13','WriteVariableNames',false,'AutoFitWidth',false);
        
            % >>> Panel III: Productive ability type probabilities
            paramout_abil = [theta_m(1:2,1), ste(1+M+20:2+M+20,1); ...
                             p3, p3_ste ];
                writetable(table(paramout_abil),join([calib.tableout,'CollectedResults.xlsx']),'Sheet','Tab_1_KeyParams','Range','B28','WriteVariableNames',false,'AutoFitWidth',false);
            
            % >>> Panel IV: Systematic education cost components
            paramout_educ = [inter(2:11,1), ste(M+23:M+32,1)];
                writetable(table(paramout_educ),join([calib.tableout,'CollectedResults.xlsx']),'Sheet','Tab_1_KeyParams','Range','B35','WriteVariableNames',false,'AutoFitWidth',false);
    
    
        % --------------------------------------------------------------------
        %%% Table SWA.3: Parameter estimates: employment risks
            % >>> Panel I: Job offers
            paramout_offer = [phi_o(1:6), ste(M+15:M+20,1)];
                writetable(table(paramout_offer),join([calib.tableout,'CollectedResults.xlsx']),'Sheet','Tab_SWA3_EmplRisk','Range','B5','WriteVariableNames',false,'AutoFitWidth',false)
    
    
        % --------------------------------------------------------------------
        %%% Table 3: Job offer and involuntary separation probabilities
        out_off_led = [o(1,1,1,11)'      o(1,1,1,31)'      o(1,1,1,36)'      o(1,1,1,41)'       ; ...
                       o_ste(1,1,1,11)'  o_ste(1,1,1,31)'  o_ste(1,1,1,36)'  o_ste(1,1,1,41)'   ; ...
                       o(1,2,1,11)'      o(1,2,1,31)'      o(1,2,1,36)'      o(1,2,1,41)'       ; ...
                       o_ste(1,2,1,11)'  o_ste(1,2,1,31)'  o_ste(1,2,1,36)'  o_ste(1,2,1,41)'   ];
            writetable(table(out_off_led),join([calib.tableout,'CollectedResults.xlsx']),'Sheet','Tab_3_OffSep','Range','C5','WriteVariableNames',false,'AutoFitWidth',false);
        
        out_off_hed = [o(3,1,1,11)'      o(3,1,1,31)'      o(3,1,1,36)'      o(3,1,1,41)'       ; ...
                       o_ste(3,1,1,11)'  o_ste(3,1,1,31)'  o_ste(3,1,1,36)'  o_ste(3,1,1,41)'   ; ...
                       o(3,2,1,11)'      o(3,2,1,31)'      o(3,2,1,36)'      o(3,2,1,41)'       ; ...
                       o_ste(3,2,1,11)'  o_ste(3,2,1,31)'  o_ste(3,2,1,36)'  o_ste(3,2,1,41)'   ];
            writetable(table(out_off_hed),join([calib.tableout,'CollectedResults.xlsx']),'Sheet','Tab_3_OffSep','Range','C11','WriteVariableNames',false,'AutoFitWidth',false);
    
        out_sep_led = [s(1,1,1,11)'      s(1,1,1,31)'      s(1,1,1,36)'      s(1,1,1,41)'       ; ...
                       s_ste(1,1,1,11)'  s_ste(1,1,1,31)'  s_ste(1,1,1,36)'  s_ste(1,1,1,41)'   ; ...
                       s(1,2,1,11)'      s(1,2,1,31)'      s(1,2,1,36)'      s(1,2,1,41)'       ; ...
                       s_ste(1,2,1,11)'  s_ste(1,2,1,31)'  s_ste(1,2,1,36)'  s_ste(1,2,1,41)'   ];
            writetable(table(out_sep_led),join([calib.tableout,'CollectedResults.xlsx']),'Sheet','Tab_3_OffSep','Range','C18','WriteVariableNames',false,'AutoFitWidth',false);
        
        out_sep_hed = [s(3,1,1,11)'      s(3,1,1,31)'      s(3,1,1,36)'      s(3,1,1,41)'       ; ...
                       s_ste(3,1,1,11)'  s_ste(3,1,1,31)'  s_ste(3,1,1,36)'  s_ste(3,1,1,41)'   ; ...
                       s(3,2,1,11)'      s(3,2,1,31)'      s(3,2,1,36)'      s(3,2,1,41)'       ; ...
                       s_ste(3,2,1,11)'  s_ste(3,2,1,31)'  s_ste(3,2,1,36)'  s_ste(3,2,1,41)'   ];
            writetable(table(out_sep_hed),join([calib.tableout,'CollectedResults.xlsx']),'Sheet','Tab_3_OffSep','Range','C24','WriteVariableNames',false,'AutoFitWidth',false);

    elseif calib.switch_estimexport == 0
        disp('Estimation results not exported...')

    end

end