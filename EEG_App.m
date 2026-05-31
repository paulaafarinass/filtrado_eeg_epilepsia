function eeg_App()
    datos           = [];
    info_archivo    = [];
    nombres_canales = {};
    s_sin_continua  = [];
    t               = [];
    t_muestreo      = [];
    f_muestreo      = [];
    eeg1gamma       = [];
    eeg1beta        = [];
    eeg1alpha       = [];
    eeg1theta       = [];
    eeg1delta       = [];

    fig = uifigure('Name', 'Analizador EEG', 'Position', [80 50 1150 760]);
    pCtrl = uipanel(fig, 'Position', [10 10 260 740], 'BackgroundColor', [1 1 1]);

    uilabel(pCtrl, 'Text', 'Analizador EEG', ...
        'Position', [10 705 240 28], 'FontSize', 16, 'FontWeight', 'bold');
    uilabel(pCtrl, 'Text', 'Filtrado wavelet + deteccion epileptiforme', ...
        'Position', [10 686 240 18], 'FontSize', 10, 'FontColor', [0.5 0.5 0.5]);

    uilabel(pCtrl, 'Text', '1. Cargar archivo', ...
        'Position', [10 658 240 18], 'FontSize', 12, 'FontWeight', 'bold');
    uibutton(pCtrl, 'Text', 'Seleccionar .edf', ...
        'Position', [10 628 240 26], ...
        'BackgroundColor', [0.09 0.37 0.65], 'FontColor', [1 1 1], ...
        'FontWeight', 'bold', 'ButtonPushedFcn', @cargarArchivo);
    lblArchivo = uilabel(pCtrl, 'Text', 'Sin archivo', ...
        'Position', [10 608 240 18], 'FontSize', 10, 'FontColor', [0.5 0.5 0.5]);

    uilabel(pCtrl, 'Text', '2. Parametros', ...
        'Position', [10 580 240 18], 'FontSize', 12, 'FontWeight', 'bold');
    uilabel(pCtrl, 'Text', 'Segundos a procesar:', ...
        'Position', [10 558 155 18], 'FontSize', 11);
    spnSegundos = uispinner(pCtrl, 'Value', 10, 'Limits', [1 600], ...
        'Position', [168 556 82 22]);
    uilabel(pCtrl, 'Text', 'Canal a visualizar:', ...
        'Position', [10 530 155 18], 'FontSize', 11);
    ddCanal = uidropdown(pCtrl, 'Items', {'(cargar archivo)'}, ...
        'Position', [10 508 240 24]);
    uilabel(pCtrl, 'Text', 'Umbral deteccion (sigma):', ...
        'Position', [10 482 155 18], 'FontSize', 11);
    spnSigma = uispinner(pCtrl, 'Value', 3, 'Limits', [1 6], 'Step', 0.5, ...
        'Position', [168 480 82 22]);

    uilabel(pCtrl, 'Text', '3. Ejecutar', ...
        'Position', [10 452 240 18], 'FontSize', 12, 'FontWeight', 'bold');
    uibutton(pCtrl, 'Text', 'Filtrar senal', ...
        'Position', [10 422 240 28], ...
        'BackgroundColor', [0.06 0.43 0.34], 'FontColor', [1 1 1], ...
        'FontWeight', 'bold', 'FontSize', 13, ...
        'ButtonPushedFcn', @filtrarSenal);
    uibutton(pCtrl, 'Text', 'Detectar eventos epileptiformes', ...
        'Position', [10 388 240 28], ...
        'BackgroundColor', [0.52 0.29 0.04], 'FontColor', [1 1 1], ...
        'FontWeight', 'bold', 'ButtonPushedFcn', @detectarEventos);
    uibutton(pCtrl, 'Text', 'Guardar informe', ...
        'Position', [10 354 240 28], ...
        'BackgroundColor', [0.25 0.25 0.25], 'FontColor', [1 1 1], ...
        'FontWeight', 'bold', 'ButtonPushedFcn', @guardarInforme);

    lblEstado = uilabel(pCtrl, 'Text', 'Listo', ...
        'Position', [10 326 240 20], 'FontSize', 10, 'FontColor', [0.4 0.4 0.4]);

    uilabel(pCtrl, 'Text', '4. Resultados', ...
        'Position', [10 298 240 18], 'FontSize', 12, 'FontWeight', 'bold');
    lblNEventos = uilabel(pCtrl, 'Text', 'Eventos detectados: --', ...
        'Position', [10 274 240 20], 'FontSize', 11);
    lblDiag = uilabel(pCtrl, 'Text', 'Diagnostico: --', ...
        'Position', [10 250 240 44], 'FontSize', 11, ...
        'FontWeight', 'bold', 'WordWrap', 'on');

    uilabel(pCtrl, 'Text', ...
        'Herramienta de apoyo academico. No sustituye diagnostico neurologico clinico.', ...
        'Position', [10 10 240 80], 'FontSize', 9, ...
        'FontColor', [0.5 0.4 0.0], 'WordWrap', 'on');

    pGraf = uipanel(fig, 'Position', [280 10 860 740], 'BackgroundColor', [1 1 1]);
    tg       = uitabgroup(pGraf, 'Position', [5 5 850 728]);
    tabSenal = uitab(tg, 'Title', 'Senal filtrada');
    tabEvt   = uitab(tg, 'Title', 'Eventos');
    tabDiag  = uitab(tg, 'Title', 'Diagnostico');

    alturaAx    = 118;
    gapAx       = 8;
    yBase       = 12;
    coloresBanda = {[0.64 0.18 0.18], [0.52 0.29 0.04], [0.33 0.29 0.72], ...
                    [0.06 0.43 0.34], [0.09 0.37 0.65]};
    titulosBanda = {'Gamma (32-64 Hz)', 'Beta (16-32 Hz)', 'Alpha (8-16 Hz)', ...
                    'Theta (4-8 Hz)', 'Delta (0.5-4 Hz)'};

    axBandas = gobjects(5,1);
    for k = 1:5
        ypos = yBase + (5-k) * (alturaAx + gapAx);
        axBandas(k) = uiaxes(tabSenal, 'Position', [10 ypos 825 alturaAx]);
        title(axBandas(k), titulosBanda{k}, 'FontSize', 10, ...
            'FontWeight', 'bold', 'Color', coloresBanda{k});
        ylabel(axBandas(k), 'Amplitud (uV)', 'FontSize', 9);
        if k == 5
            xlabel(axBandas(k), 'Tiempo (s)', 'FontSize', 9);
        end
        grid(axBandas(k), 'on');
    end

    axEvt = uiaxes(tabEvt, 'Position', [10 350 825 355]);
    title(axEvt, 'Delta con eventos marcados');
    xlabel(axEvt, 'Tiempo (s)'); ylabel(axEvt, 'Amplitud (uV)');
    grid(axEvt, 'on');

    tblEvt = uitable(tabEvt, 'Position', [10 10 825 330], ...
        'ColumnName', {'Tiempo (s)', 'Canal', 'Banda', 'Amplitud (uV)'}, ...
        'ColumnWidth', {100, 160, 90, 120}, 'FontSize', 10);

    txtDiag = uitextarea(tabDiag, 'Position', [10 10 825 700], ...
        'FontSize', 11, 'Editable', 'off', ...
        'Value', {'Ejecuta el filtrado y la deteccion para ver el diagnostico.'});

    function cargarArchivo(~, ~)
        [archivo, ruta] = uigetfile('*.edf', 'Seleccionar archivo EDF');
        if archivo == 0, return; end
        rutaCompleta = fullfile(ruta, archivo);
        lblEstado.Text = 'Cargando...'; drawnow;
       
        datos           = edfread(rutaCompleta);
        info_archivo    = edfinfo(rutaCompleta);
        nombres_canales = datos.Properties.VariableNames;
        
        ddCanal.Items    = nombres_canales;
        ddCanal.Value    = nombres_canales{1};
        lblArchivo.Text  = archivo;
        lblArchivo.FontColor = [0.06 0.43 0.34];
        lblEstado.Text   = sprintf('Cargado. Canales: %d', length(nombres_canales));
    end

    function filtrarSenal(~, ~)
        if isempty(datos)
            uialert(fig, 'Primero carga un archivo EDF.', 'Sin datos');
            return
        end
        lblEstado.Text = 'Procesando...'; drawnow;
        
        n_muestras_total = length(cell2mat(datos.(nombres_canales{1})));
        num_canales      = length(nombres_canales);
        s                = zeros(n_muestras_total, num_canales);
        for i = 1:num_canales
            s(:, i) = cell2mat(datos.(nombres_canales{i}));
        end
        s_sin_continua = s - mean(s, 1);
        
        f_muestreo = info_archivo.NumSamples(1) / ...
                     seconds(info_archivo.DataRecordDuration);
        t_muestreo = 1 / f_muestreo;
        canal_a_ver = find(strcmp(nombres_canales, ddCanal.Value), 1);
        
        d = designfilt('bandstopiir', 'FilterOrder', 4, ...
            'HalfPowerFrequency1', 49, 'HalfPowerFrequency2', 51, ...
            'SampleRate', f_muestreo);
        s_sin_continua(:, canal_a_ver) = filtfilt(d, s_sin_continua(:, canal_a_ver));
        
        hp = designfilt('highpassiir', 'FilterOrder', 4, ...
            'HalfPowerFrequency', 0.5, 'SampleRate', f_muestreo);
        s_sin_continua(:, canal_a_ver) = filtfilt(hp, s_sin_continua(:, canal_a_ver));
       
        segundos_a_procesar = spnSegundos.Value;
        max_muestras        = round(segundos_a_procesar * f_muestreo);
        n_total        = size(s_sin_continua, 1);
        s_sin_continua = s_sin_continua(1:min(max_muestras, n_total), :);
        n_muestras     = size(s_sin_continua, 1);
        t              = (0:n_muestras-1) * t_muestreo;
      
        wt = modwt(s_sin_continua(:, canal_a_ver), 'db8');
        for nivel = [3, 4]
            umbral      = spnSigma.Value * median(abs(wt(nivel,:))) / 0.6745;
            wt(nivel,:) = wthresh(wt(nivel,:), 's', umbral);
        end
        
        wtrec      = zeros(size(wt)); wtrec(3,:) = wt(3,:);
        eeg1gamma  = imodwt(wtrec, 'db8');
        wtrec      = zeros(size(wt)); wtrec(4,:) = wt(4,:);
        eeg1beta   = imodwt(wtrec, 'db8');
        wtrec      = zeros(size(wt)); wtrec(5,:) = wt(5,:);
        eeg1alpha  = imodwt(wtrec, 'db8');
        wtrec      = zeros(size(wt)); wtrec(6,:) = wt(6,:);
        eeg1theta  = imodwt(wtrec, 'db8');
        wtrec      = zeros(size(wt));
        wtrec(7,:) = wt(7,:); wtrec(8,:) = wt(8,:); wtrec(9,:) = wt(9,:);
        eeg1delta  = imodwt(wtrec, 'db8');
        
        senales = {eeg1gamma, eeg1beta, eeg1alpha, eeg1theta, eeg1delta};
        for k = 1:5
            cla(axBandas(k));
            plot(axBandas(k), t, senales{k}, ...
                'Color', coloresBanda{k}, 'LineWidth', 0.8);
            axBandas(k).XLim = [0 t(end)];
            title(axBandas(k), titulosBanda{k}, 'FontSize', 10, ...
                'FontWeight', 'bold', 'Color', coloresBanda{k});
            ylabel(axBandas(k), 'Amplitud (uV)', 'FontSize', 9);
            if k == 5
                xlabel(axBandas(k), 'Tiempo (s)', 'FontSize', 9);
            end
            grid(axBandas(k), 'on');
        end
        tabSenal.Title = sprintf('Senal — %s', nombres_canales{canal_a_ver});
        
        lblEstado.Text = sprintf('Filtrado OK. Canal: %s', nombres_canales{canal_a_ver});
        tg.SelectedTab = tabSenal;
    end

    function detectarEventos(~, ~)
        UMBRAL_ENERGIA_DELTA_PCT = 60;
        UMBRAL_TIEMPO_CRISIS_S = 10;
        if isempty(eeg1delta)
            uialert(fig, 'Primero filtra la senal.', 'Sin datos');
            return
        end
        lblEstado.Text = 'Detectando crisis (Regla 10s)...'; drawnow;
        canal_a_ver = find(strcmp(nombres_canales, ddCanal.Value), 1);
        
        % LÓGICA DE VENTANAS: Análisis de energía cada 1 segundo
        tamano_ventana_s = 1; 
        muestras_ventana = round(tamano_ventana_s * f_muestreo);
        n_ventanas       = floor(length(eeg1delta) / muestras_ventana);
        es_patologica    = false(1, n_ventanas);
        
        % 1. Calcular energía relativa por ventana
        for v = 1:n_ventanas
            idx_inicio = (v-1) * muestras_ventana + 1;
            idx_fin    = v * muestras_ventana;
            
            e_d = mean(eeg1delta(idx_inicio:idx_fin).^2);
            e_t = mean(eeg1theta(idx_inicio:idx_fin).^2);
            e_a = mean(eeg1alpha(idx_inicio:idx_fin).^2);
            e_b = mean(eeg1beta(idx_inicio:idx_fin).^2);
            e_g = mean(eeg1gamma(idx_inicio:idx_fin).^2);
            
            e_total = e_d + e_t + e_a + e_b + e_g;
            if e_total == 0, e_total = 1; end
            energia_delta = (e_d / e_total) * 100;
            
            % Umbral heurístico: Si supera el 60%, esa ventana es anómala
            es_patologica(v) = energia_delta > UMBRAL_ENERGIA_DELTA_PCT; 
        end
        
        % 2. Buscar rachas continuas >= 10 segundos
        crisis_detectadas = 0;
        tabla_ev = {};
        duracion_actual = 0;
        tiempo_inicio_crisis = 0;
        indice_crisis=1;
        
        for v = 1:n_ventanas
            if es_patologica(v)
                if duracion_actual == 0
                    tiempo_inicio_crisis = (v-1) * tamano_ventana_s;
                end
                duracion_actual = duracion_actual + tamano_ventana_s;
            else
                % Si se rompe la racha patológica, evaluamos cuánto duró
                if duracion_actual >= UMBRAL_TIEMPO_CRISIS_S
                    crisis_detectadas = crisis_detectadas + 1;
                    tabla_ev{indice_crisis, 1} = round(tiempo_inicio_crisis, 2);
                    tabla_ev{indice_crisis,   2} = round(tiempo_inicio_crisis + duracion_actual, 2);
                    tabla_ev{indice_crisis,   3} = duracion_actual;
                    tabla_ev{indice_crisis,   4} = 'Crisis EEG';

                    indice_crisis=indice_crisis+1;
                end
                duracion_actual = 0; % Reiniciamos el contador
            end
        end
        
        % Comprobar si la señal termina justo durante una crisis en curso
        if duracion_actual >= UMBRAL_TIEMPO_CRISIS_S
            crisis_detectadas = crisis_detectadas + 1;
            tabla_ev{indice_crisis, 1} = round(tiempo_inicio_crisis, 2);
            tabla_ev{indice_crisis,   2} = round(tiempo_inicio_crisis + duracion_actual, 2);
            tabla_ev{indice_crisis,   3} = duracion_actual;
            tabla_ev{indice_crisis,   4} = 'Crisis EEG';
        end
        
        % 3. Actualizar la interfaz y tabla
        tblEvt.ColumnName = {'Inicio (s)', 'Fin (s)', 'Duracion (s)', 'Tipo'};
        if ~isempty(tabla_ev)
            tblEvt.Data = tabla_ev;
        else
            tblEvt.Data = {0, 0, 0, '--'};
        end
        
        % 4. Dibujar la señal con las crisis sombreadas en rojo
        cla(axEvt);
        plot(axEvt, t, eeg1delta, 'Color', [0.09 0.37 0.65], 'LineWidth', 0.8);
        hold(axEvt, 'on');
        for i = 1:size(tabla_ev, 1)
            if strcmp(tabla_ev{i, 4}, 'Crisis EEG')
                t_ini = tabla_ev{i, 1};
                t_fin = tabla_ev{i, 2};
                y_lims = ylim(axEvt);
                patch(axEvt, [t_ini t_fin t_fin t_ini], ...
                     [y_lims(1) y_lims(1) y_lims(2) y_lims(2)], ...
                     'red', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
            end
        end
        hold(axEvt, 'off');
        title(axEvt, sprintf('Delta — %s (Crisis sostenidas >= 10s sombreadas)', nombres_canales{canal_a_ver}));
        xlabel(axEvt, 'Tiempo (s)'); ylabel(axEvt, 'Amplitud (uV)');
        axEvt.XLim = [0 t(end)]; grid(axEvt, 'on');
        
        lblNEventos.Text = sprintf('Crisis continuadas: %d', crisis_detectadas);
        
        % Llamar al nuevo generador de diagnóstico
        construirDiagnostico(crisis_detectadas, canal_a_ver);
        
        lblEstado.Text = sprintf('Analisis finalizado. Crisis: %d', crisis_detectadas);
        tg.SelectedTab = tabEvt;
    end

    function construirDiagnostico(crisis_detectadas, canal_a_ver)
        % Cálculo de energía global para estadística general
        total_e = mean(eeg1delta.^2) + mean(eeg1theta.^2) + ...
                  mean(eeg1alpha.^2) + mean(eeg1beta.^2)  + ...
                  mean(eeg1gamma.^2);
        if total_e == 0, total_e = 1; end
        e_delta_global = mean(eeg1delta.^2) / total_e * 100;
        e_theta_global = mean(eeg1theta.^2) / total_e * 100;
        
        if crisis_detectadas == 0 && e_delta_global < 40
            nivel  = 'SIN CRISIS - NORMAL';
            cuerpo = 'No se han detectado episodios continuados. Distribucion de energia global en rangos fisiologicos.';
            lblDiag.FontColor = [0.06 0.43 0.34];
        elseif crisis_detectadas == 0 && e_delta_global >= 40
            nivel  = 'SIN CRISIS - ACTIVIDAD LENTA';
            cuerpo = 'Ausencia de crisis epilepticas sostenidas (>10s), pero existe dominancia Delta global. Posible artefacto, paciente dormido o estado post-ictal.';
            lblDiag.FontColor = [0.52 0.29 0.04];
        else
            nivel  = 'ALERTA CLINICA - CRISIS DETECTADA';
            cuerpo = sprintf('Se ha detectado actividad epileptiforme continua. Dominancia energetica Delta >60%% mantenida durante al menos 10 segundos en %d ocasion(es).', crisis_detectadas);
            lblDiag.FontColor = [0.64 0.18 0.18];
        end
        
        lblDiag.Text = sprintf('Diagnostico: %s', nivel);
        linea = '----------------------------------------';
        txtDiag.Value = {
            linea
            'DIAGNOSTICO COMPUTACIONAL EEG (CRITERIO ICTAL 10s)'
            linea
            ''
            sprintf('Estado:  %s', nivel)
            sprintf('Canal:   %s', nombres_canales{canal_a_ver})
            sprintf('Archivo: %s', lblArchivo.Text)
            ''
            cuerpo
            ''
            linea
            'BASE DEL DIAGNOSTICO'
            linea
            ''
            sprintf('Crisis electrograficas detectadas:  %d', crisis_detectadas)
            sprintf('Criterio temporal aplicado:         >= 10 segundos')
            sprintf('Criterio energetico aplicado:       Delta > 60%%')
            sprintf('Energia relativa Delta global:      %.1f%%', e_delta_global)
            sprintf('Energia relativa Theta global:      %.1f%%', e_theta_global)
            sprintf('Duracion analizada:                 %.1f s', t(end))
            ''
            linea
            'AVISO'
            linea
            ''
            'Algoritmo adaptado a estandares de duracion (Kane et al., 2017).'
            'Herramienta de validacion academica. No sustituye la practica clinica.'
            ''
            sprintf('Generado: %s', datestr(now, 'dd/mm/yyyy HH:MM:SS'))
        };
    end

    function guardarInforme(~, ~)
        if isempty(eeg1delta)
            uialert(fig, 'Ejecuta el analisis primero.', 'Sin datos');
            return
        end
        [arch, ruta] = uiputfile('*.txt', 'Guardar informe', ...
            sprintf('Informe_EEG_%s.txt', datestr(now, 'yyyymmdd_HHMM')));
        if arch == 0, return; end
        fid = fopen(fullfile(ruta, arch), 'w', 'n', 'UTF-8');
        lineas = txtDiag.Value;
        for i = 1:length(lineas)
            fprintf(fid, '%s\n', lineas{i});
        end
        fclose(fid);
        uialert(fig, sprintf('Guardado en:\n%s', fullfile(ruta, arch)), ...
            'Informe guardado', 'Icon', 'success');
    end
end
