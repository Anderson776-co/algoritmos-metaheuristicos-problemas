%{
function resultados = pruebaAlgoritmoGeneticoAckley( ...
    nPoblacion, nDimensiones, nIteraciones, nPruebas, alpha)

% ============================================================
% PRUEBA DEL ALGORITMO GENÉTICO - FUNCIÓN ACKLEY
%
% Métodos de selección:
%   1. Elitismo
%   2. Torneo
%   3. Ruleta
%
% Estrategia de cruce:
%   BLX-Alpha
%
% El algoritmo se ejecuta hasta la etapa de apareamiento.
% No se aplica mutación.
%
% Se realizan varias pruebas independientes por cada método.
% ============================================================


%% Valores por defecto

if nargin < 1 || isempty(nPoblacion)
    nPoblacion = 20;
end

if nargin < 2 || isempty(nDimensiones)
    nDimensiones = 5;
end

if nargin < 3 || isempty(nIteraciones)
    nIteraciones = 100;
end

if nargin < 4 || isempty(nPruebas)
    nPruebas = 5;
end

if nargin < 5 || isempty(alpha)
    alpha = 0.5;
end


%% Validación de parámetros

validateattributes(nPoblacion, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(nDimensiones, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(nIteraciones, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(nPruebas, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(alpha, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'nonnegative'});


if mod(nPoblacion, 2) ~= 0
    error('El tamaño de la población debe ser par.');
end


%% Parámetros del problema

limites = [-10, 10];

% Mínimo teórico de la función Ackley modificada
valorOptimoTeorico = 3 - exp(1);

metodos = {'Elitismo', 'Torneo', 'Ruleta'};

nMetodos = numel(metodos);


%% Reservar memoria

% Mejor valor obtenido en cada prueba
mejoresValores = zeros(nMetodos, nPruebas);

% Mejor individuo obtenido en cada prueba
mejoresIndividuos = zeros( ...
    nMetodos, nPruebas, nDimensiones);

% Tiempo de cada prueba
tiempos = zeros(nMetodos, nPruebas);

% Mejor valor de cada iteración de cada prueba
mejoresIteraciones = zeros( ...
    nMetodos, nIteraciones, nPruebas);


%% ============================================================
% EJECUCIÓN DE LAS PRUEBAS
% ============================================================

for metodo = 1:nMetodos

    nombre = metodos{metodo};

    fprintf('\n=============================================\n');
    fprintf('MÉTODO DE SELECCIÓN: %s\n', nombre);
    fprintf('=============================================\n');


    for prueba = 1:nPruebas

        fprintf('\n---------------------------------------------\n');
        fprintf('Método: %s | Prueba: %d de %d\n', ...
            nombre, prueba, nPruebas);
        fprintf('---------------------------------------------\n');


        tic;


        %% 1. GENERACIÓN DE POBLACIÓN INICIAL

        poblacion = generarPoblacionInicial( ...
            nPoblacion, nDimensiones, limites);


        %% EVALUACIÓN INICIAL

        aptitud = arrayfun(@(i) ...
            ackleyFcn(poblacion(i, :)), ...
            (1:nPoblacion).');


        %% MEJOR SOLUCIÓN INICIAL

        [mejorValor, indiceMejor] = min(aptitud);

        mejorIndividuo = poblacion(indiceMejor, :);


        %% ====================================================
        % ITERACIONES DEL ALGORITMO GENÉTICO
        % ====================================================

        for iteracion = 1:nIteraciones


            %% 2. SELECCIÓN

            switch metodo

                case 1
                    % ----------------------------------------
                    % ELITISMO
                    % ----------------------------------------

                    [padres, indicesPadres] = ...
                        seleccionElitismo( ...
                        poblacion, ...
                        aptitud, ...
                        nPoblacion / 2);


                case 2
                    % ----------------------------------------
                    % TORNEO
                    % ----------------------------------------

                    [padres, indicesPadres] = ...
                        seleccionTorneo( ...
                        poblacion, ...
                        aptitud, ...
                        4, ...
                        2, ...
                        'min');


                case 3
                    % ----------------------------------------
                    % RULETA
                    % ----------------------------------------

                    [padres, indicesPadres, ~] = ...
                        seleccionRuleta( ...
                        poblacion, ...
                        aptitud, ...
                        nPoblacion / 2);

            end


            %% =================================================
            % 3. APAREAMIENTO MEDIANTE BLX-ALPHA
            % =================================================

            nPadres = size(padres, 1);

            hijos = zeros(nPadres, nDimensiones);


            for i = 1:2:nPadres

                padre1 = padres(i, :);
                padre2 = padres(i + 1, :);

                [hijo1, hijo2] = ...
                    cruceBLXAlpha(padre1, padre2, alpha);

                hijos(i, :) = hijo1;
                hijos(i + 1, :) = hijo2;

            end


            %% =================================================
            % 4. FORMACIÓN DE LA NUEVA GENERACIÓN
            % =================================================

            poblacionNueva = [padres; hijos];


            %% =================================================
            % VERIFICACIÓN DEL TAMAÑO DE LA POBLACIÓN
            % =================================================

            if size(poblacionNueva, 1) ~= nPoblacion

                error(['El método %s produjo una población de ', ...
                    '%d individuos. Se esperaban %d.'], ...
                    nombre, ...
                    size(poblacionNueva, 1), ...
                    nPoblacion);

            end


            % La población para la siguiente iteración
            % está formada por los padres seleccionados y los hijos.

            poblacion = poblacionNueva;


            %% =================================================
            % EVALUACIÓN DE LA NUEVA POBLACIÓN
            % =================================================

            aptitud = arrayfun(@(i) ...
                ackleyFcn(poblacion(i, :)), ...
                (1:nPoblacion).');


            %% =================================================
            % MEJOR RESULTADO DE LA ITERACIÓN
            % =================================================

            [mejorValorIteracion, indiceMejorIteracion] = ...
                min(aptitud);


            % Guardar mejor resultado de esta iteración

            mejoresIteraciones( ...
                metodo, iteracion, prueba) = ...
                mejorValorIteracion;


            %% =================================================
            % ACTUALIZAR MEJOR SOLUCIÓN ENCONTRADA
            % =================================================

            if mejorValorIteracion < mejorValor

                mejorValor = mejorValorIteracion;

                mejorIndividuo = ...
                    poblacion(indiceMejorIteracion, :);

            end

        end


        %% ====================================================
        % TIEMPO DE EJECUCIÓN DE ESTA PRUEBA
        % ====================================================

        tiempoEjecucion = toc;


        %% ====================================================
        % GUARDAR RESULTADOS DE ESTA PRUEBA
        % ====================================================

        tiempos(metodo, prueba) = tiempoEjecucion;

        mejoresValores(metodo, prueba) = mejorValor;

        mejoresIndividuos(metodo, prueba, :) = ...
            mejorIndividuo;


        %% ====================================================
        % MOSTRAR RESULTADOS DE ESTA PRUEBA
        % ====================================================

        fprintf('Tiempo de ejecución: %.6f segundos\n', ...
            tiempoEjecucion);

        fprintf('Mejor valor f(X): %.10f\n', ...
            mejorValor);

        fprintf('Mejor individuo X:\n');

        disp(mejorIndividuo);

    end


    %% ========================================================
    % RESUMEN DEL MÉTODO
    % ========================================================

    % Promedio de los mejores resultados de las pruebas

    promedio = mean(mejoresValores(metodo, :));


    % RMSE respecto al óptimo teórico

    errores = ...
        mejoresValores(metodo, :) - valorOptimoTeorico;

    RMSE = sqrt(mean(errores.^2));


    % Tiempo promedio

    tiempoPromedio = mean(tiempos(metodo, :));


    % Mejor resultado entre todas las pruebas

    [mejorResultado, indiceMejorPrueba] = ...
        min(mejoresValores(metodo, :));


    % Individuo que produjo el mejor resultado

    mejorIndividuoFinal = squeeze( ...
        mejoresIndividuos( ...
        metodo, indiceMejorPrueba, :)).';


    %% ========================================================
    % GUARDAR RESULTADOS DEL MÉTODO
    % ========================================================

    resultados(metodo).seleccion = nombre;


    % --------------------------------------------------------
    % Datos individuales de cada prueba
    % --------------------------------------------------------

    resultados(metodo).pruebas = struct();

    for prueba = 1:nPruebas

        resultados(metodo).pruebas(prueba).numero = prueba;

        resultados(metodo).pruebas(prueba).tiempo = ...
            tiempos(metodo, prueba);

        resultados(metodo).pruebas(prueba).mejorValor = ...
            mejoresValores(metodo, prueba);

        resultados(metodo).pruebas(prueba).mejorIndividuo = ...
            squeeze(mejoresIndividuos( ...
            metodo, prueba, :)).';

        resultados(metodo).pruebas(prueba).mejoresIteraciones = ...
            mejoresIteraciones(metodo, :, prueba).';

    end


    % --------------------------------------------------------
    % Estadísticas generales del método
    % --------------------------------------------------------

    resultados(metodo).tiempo = tiempoPromedio;

    resultados(metodo).mejorValor = mejorResultado;

    resultados(metodo).mejorIndividuo = mejorIndividuoFinal;

    resultados(metodo).promedio = promedio;

    resultados(metodo).RMSE = RMSE;

    resultados(metodo).mejoresPruebas = ...
        mejoresValores(metodo, :);

    resultados(metodo).tiemposPruebas = ...
        tiempos(metodo, :);

    resultados(metodo).mejoresIndividuos = ...
        squeeze(mejoresIndividuos(metodo, :, :));


    %% ========================================================
    % MOSTRAR RESUMEN DEL MÉTODO
    % ========================================================

    fprintf('\n=============================================\n');
    fprintf('RESUMEN DEL MÉTODO: %s\n', nombre);
    fprintf('=============================================\n');

    fprintf('Promedio f(X): %.10f\n', promedio);

    fprintf('RMSE: %.10f\n', RMSE);

    fprintf('Tiempo promedio: %.6f segundos\n', ...
        tiempoPromedio);

    fprintf('Mejor resultado de todas las pruebas: %.10f\n', ...
        mejorResultado);

    fprintf('Individuo que produce el mejor resultado:\n');

    disp(mejorIndividuoFinal);

end


%% ============================================================
% TABLA RESUMEN
% ============================================================

fprintf('\n\n============================================================\n');
fprintf('                 RESULTADOS FINALES\n');
fprintf('============================================================\n');

fprintf('%-15s %-15s %-15s %-15s\n', ...
    'Selección', ...
    'Tiempo (s)', ...
    'Promedio f(X)', ...
    'RMSE');

fprintf('------------------------------------------------------------\n');


for metodo = 1:nMetodos

    fprintf('%-15s %-15.6f %-15.10f %-15.10f\n', ...
        resultados(metodo).seleccion, ...
        resultados(metodo).tiempo, ...
        resultados(metodo).promedio, ...
        resultados(metodo).RMSE);

end


fprintf('============================================================\n');


%% ============================================================
% TABLA DE RESULTADOS
% ============================================================

tablaResumen = table( ...
    metodos.', ...
    [resultados.tiempo].', ...
    [resultados.promedio].', ...
    [resultados.RMSE].', ...
    [resultados.mejorValor].', ...
    'VariableNames', { ...
    'MetodoSeleccion', ...
    'TiempoPromedio_s', ...
    'Promedio_fX', ...
    'RMSE', ...
    'Mejor_fX'});


%% ============================================================
% GUARDAR RESULTADOS GENERALES
% ============================================================

resultadosParametros = struct();

resultadosParametros.nPoblacion = nPoblacion;
resultadosParametros.nDimensiones = nDimensiones;
resultadosParametros.nIteraciones = nIteraciones;
resultadosParametros.nPruebas = nPruebas;
resultadosParametros.alpha = alpha;

resultados(1).parametros = resultadosParametros;

resultados(1).valorOptimoTeorico = ...
    valorOptimoTeorico;

resultados(1).metodos = metodos;

resultados(1).tabla = tablaResumen;


%% ============================================================
% MOSTRAR TABLA
% ============================================================

fprintf('\n============================================================\n');
fprintf('TABLA RESUMEN\n');
fprintf('============================================================\n');

disp(tablaResumen);

end
%}

%{
function resultados = pruebaAlgoritmoGeneticoAckleyTorneo( ...
        nPoblacion, nDimensiones, nIteraciones, nPruebas, alpha)

    % ============================================================
    % PRUEBA DEL ALGORITMO GENÉTICO - FUNCIÓN ACKLEY
    %
    % Método de selección:
    %   Torneo
    %
    % Estrategia de cruce:
    %   BLX-Alpha
    %
    % Mutación:
    %   No se aplica
    %
    % El objetivo de esta función es estudiar el efecto del
    % número de iteraciones sobre el desempeño del algoritmo.
    %
    % Se realizan varias pruebas independientes.
    %
    % Se reporta:
    %   - Tiempo de ejecución
    %   - Mejor f(X)
    %   - Mejor individuo X
    %   - Promedio de los mejores resultados
    %   - RMSE respecto al óptimo teórico
    % ============================================================


    % ============================================================
    % VALORES POR DEFECTO
    % ============================================================

    if nargin < 1 || isempty(nPoblacion)
        nPoblacion = 20;
    end

    if nargin < 2 || isempty(nDimensiones)
        nDimensiones = 5;
    end

    if nargin < 3 || isempty(nIteraciones)
        nIteraciones = 200;
    end

    if nargin < 4 || isempty(nPruebas)
        nPruebas = 5;
    end

    if nargin < 5 || isempty(alpha)
        alpha = 0.5;
    end


    % ============================================================
    % VALIDACIÓN DE PARÁMETROS
    % ============================================================

    validateattributes(nPoblacion, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    validateattributes(nDimensiones, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    validateattributes(nIteraciones, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    validateattributes(nPruebas, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    validateattributes(alpha, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'nonnegative'});


    % La población debe ser par para formar parejas
    if mod(nPoblacion, 2) ~= 0
        error('El tamaño de la población debe ser par.');
    end


    % ============================================================
    % PARÁMETROS DEL PROBLEMA
    % ============================================================

    limites = [-10, 10];

    % Mínimo teórico de la Ackley modificada
    valorOptimoTeorico = 3 - exp(1);


    % ============================================================
    % RESERVAR MEMORIA
    % ============================================================

    % Mejor valor encontrado en cada prueba
    mejoresValores = zeros(nPruebas, 1);

    % Mejor individuo de cada prueba
    mejoresIndividuos = zeros(nPruebas, nDimensiones);

    % Tiempo de ejecución de cada prueba
    tiempos = zeros(nPruebas, 1);

    % Mejor valor encontrado en cada iteración
    % de cada prueba
    mejoresIteraciones = zeros(nIteraciones, nPruebas);


    % ============================================================
    % EJECUCIÓN DE LAS PRUEBAS
    % ============================================================

    for prueba = 1:nPruebas

        fprintf('\n=============================================\n');
        fprintf('SELECCIÓN: TORNEO\n');
        fprintf('PRUEBA: %d de %d\n', prueba, nPruebas);
        fprintf('ITERACIONES: %d\n', nIteraciones);
        fprintf('=============================================\n');


        tic;


        % ========================================================
        % VARIABLES DE LA PRUEBA
        % ========================================================

        mejorValor = Inf;
        mejorIndividuo = [];


        % ========================================================
        % 1. GENERACIÓN DE LA POBLACIÓN INICIAL
        % ========================================================

        poblacion = generarPoblacionInicial( ...
            nPoblacion, ...
            nDimensiones, ...
            limites);


        % ========================================================
        % 2. EVALUACIÓN INICIAL
        % ========================================================

        aptitud = arrayfun(@(i) ...
            ackleyFcn(poblacion(i, :)), ...
            (1:nPoblacion).');


        % ========================================================
        % MEJOR SOLUCIÓN INICIAL
        % ========================================================

        [mejorValorInicial, indiceMejor] = min(aptitud);

        mejorValor = mejorValorInicial;

        mejorIndividuo = poblacion(indiceMejor, :);


        % ========================================================
        % 3. ITERACIONES
        % ========================================================

        for iteracion = 1:nIteraciones


            % ====================================================
            % SELECCIÓN POR TORNEO
            % ====================================================

            [padres, ~] = seleccionTorneo( ...
                poblacion, ...
                aptitud, ...
                4, ...       % Tamaño del torneo
                2, ...       % Ganadores
                'min');


            % ====================================================
            % CRUCE BLX-ALPHA
            % ====================================================

            nPadres = size(padres, 1);

            hijos = zeros(nPadres, nDimensiones);


            for i = 1:2:nPadres

                padre1 = padres(i, :);
                padre2 = padres(i + 1, :);

                [hijo1, hijo2] = ...
                    cruceBLXAlpha(padre1, padre2, alpha);

                hijos(i, :) = hijo1;

                hijos(i + 1, :) = hijo2;

            end


            % ====================================================
            % FORMACIÓN DE LA NUEVA POBLACIÓN
            % ====================================================

            poblacionNueva = [padres; hijos];


            % ====================================================
            % VERIFICAR TAMAÑO
            % ====================================================

            if size(poblacionNueva, 1) ~= nPoblacion

                error(['El método de torneo produjo una población ', ...
                    'de %d individuos. Se esperaban %d.'], ...
                    size(poblacionNueva, 1), ...
                    nPoblacion);

            end


            % ====================================================
            % ACTUALIZAR POBLACIÓN
            % ====================================================

            poblacion = poblacionNueva;


            % ====================================================
            % EVALUACIÓN DE LA NUEVA POBLACIÓN
            % ====================================================

            aptitud = arrayfun(@(i) ...
                ackleyFcn(poblacion(i, :)), ...
                (1:nPoblacion).');


            % ====================================================
            % MEJOR RESULTADO DE LA ITERACIÓN
            % ====================================================

            [mejorValorIteracion, indiceMejorIteracion] = ...
                min(aptitud);


            % Guardar mejor valor de esta iteración

            mejoresIteraciones(iteracion, prueba) = ...
                mejorValorIteracion;


            % ====================================================
            % ACTUALIZAR MEJOR SOLUCIÓN GLOBAL
            % ====================================================

            if mejorValorIteracion < mejorValor

                mejorValor = mejorValorIteracion;

                mejorIndividuo = ...
                    poblacion(indiceMejorIteracion, :);

            end

        end


        % ========================================================
        % FINALIZACIÓN DE LA PRUEBA
        % ========================================================

        tiempoEjecucion = toc;


        % ========================================================
        % GUARDAR RESULTADOS DE LA PRUEBA
        % ========================================================

        tiempos(prueba) = tiempoEjecucion;

        mejoresValores(prueba) = mejorValor;

        mejoresIndividuos(prueba, :) = ...
            mejorIndividuo;


        % ========================================================
        % MOSTRAR RESULTADOS DE LA PRUEBA
        % ========================================================

        fprintf('\nTiempo de ejecución: %.6f segundos\n', ...
            tiempoEjecucion);

        fprintf('Mejor valor f(X): %.10f\n', ...
            mejorValor);

        fprintf('Mejor individuo X:\n');

        disp(mejorIndividuo);

    end


    % ============================================================
    % ESTADÍSTICAS GENERALES
    % ============================================================

    % Promedio de los mejores resultados
    promedio = mean(mejoresValores);


    % ============================================================
    % RMSE
    %
    % Se calcula respecto al óptimo teórico de la función.
    %
    % RMSE = sqrt(mean((f(X) - f_optimo)^2))
    % ============================================================

    errores = ...
        mejoresValores - valorOptimoTeorico;

    RMSE = sqrt(mean(errores.^2));


    % ============================================================
    % TIEMPO PROMEDIO
    % ============================================================

    tiempoPromedio = mean(tiempos);


    % ============================================================
    % MEJOR RESULTADO GLOBAL
    % ============================================================

    [mejorResultado, indiceMejorPrueba] = ...
        min(mejoresValores);


    mejorIndividuoFinal = ...
        mejoresIndividuos(indiceMejorPrueba, :);


    % ============================================================
    % GUARDAR RESULTADOS
    % ============================================================

    resultados.seleccion = 'Torneo';

    resultados.cruce = 'BLX-Alpha';

    resultados.nPoblacion = nPoblacion;

    resultados.nDimensiones = nDimensiones;

    resultados.nIteraciones = nIteraciones;

    resultados.nPruebas = nPruebas;

    resultados.alpha = alpha;

    resultados.valorOptimoTeorico = ...
        valorOptimoTeorico;


    % ============================================================
    % DATOS DE CADA PRUEBA
    % ============================================================

    resultados.pruebas = struct();


    for prueba = 1:nPruebas

        resultados.pruebas(prueba).numero = ...
            prueba;

        resultados.pruebas(prueba).tiempo = ...
            tiempos(prueba);

        resultados.pruebas(prueba).mejorValor = ...
            mejoresValores(prueba);

        resultados.pruebas(prueba).mejorIndividuo = ...
            mejoresIndividuos(prueba, :);

        resultados.pruebas(prueba).mejoresIteraciones = ...
            mejoresIteraciones(:, prueba);

    end


    % ============================================================
    % ESTADÍSTICAS GENERALES
    % ============================================================

    resultados.tiempoPromedio = ...
        tiempoPromedio;

    resultados.promedio = ...
        promedio;

    resultados.mejorValor = ...
        mejorResultado;

    resultados.mejorIndividuo = ...
        mejorIndividuoFinal;

    resultados.RMSE = ...
        RMSE;

    resultados.mejoresPruebas = ...
        mejoresValores;

    resultados.tiemposPruebas = ...
        tiempos;

    resultados.mejoresIndividuos = ...
        mejoresIndividuos;

    resultados.mejoresIteraciones = ...
        mejoresIteraciones;


    % ============================================================
    % MOSTRAR RESUMEN
    % ============================================================

    fprintf('\n\n============================================================\n');
    fprintf('       RESULTADOS - TORNEO + BLX-ALPHA\n');
    fprintf('============================================================\n');

    fprintf('Número de iteraciones: %d\n', ...
        nIteraciones);

    fprintf('Número de pruebas: %d\n', ...
        nPruebas);

    fprintf('Alpha: %.4f\n', ...
        alpha);

    fprintf('------------------------------------------------------------\n');

    fprintf('%-15s %-15s %-15s\n', ...
        'Prueba', ...
        'Tiempo (s)', ...
        'Mejor f(X)');

    fprintf('------------------------------------------------------------\n');


    % ============================================================
    % RESULTADOS INDIVIDUALES
    % ============================================================

    for prueba = 1:nPruebas

        fprintf('%-15d %-15.6f %-15.10f\n', ...
            prueba, ...
            tiempos(prueba), ...
            mejoresValores(prueba));

    end


    fprintf('------------------------------------------------------------\n');


    % ============================================================
    % RESULTADOS GLOBALES
    % ============================================================

    fprintf('%-15s %-15.6f %-15.10f\n', ...
        'PROMEDIO', ...
        tiempoPromedio, ...
        promedio);


    fprintf('RMSE: %.10f\n', ...
        RMSE);


    fprintf('Mejor resultado global: %.10f\n', ...
        mejorResultado);


    fprintf('Obtenido en la prueba: %d\n', ...
        indiceMejorPrueba);


    fprintf('Individuo X que produce el mejor resultado:\n');

    disp(mejorIndividuoFinal);


    fprintf('============================================================\n');


    % ============================================================
    % TABLA DE RESULTADOS
    % ============================================================

    tablaResumen = table( ...
        (1:nPruebas).', ...
        tiempos, ...
        mejoresValores, ...
        'VariableNames', { ...
        'Prueba', ...
        'Tiempo_s', ...
        'Mejor_fX'});


    resultados.tablaPruebas = ...
        tablaResumen;


    fprintf('\n============================================================\n');
    fprintf('TABLA DE RESULTADOS POR PRUEBA\n');
    fprintf('============================================================\n');

    disp(tablaResumen);

end
%}


function resultados = pruebaAlgoritmoGeneticoAckleyMutacion( ...
        nPoblacion, nDimensiones, nIteraciones, nPruebas, ...
        alpha, probMutacion, desviacion)

% ============================================================
% PRUEBA DEL ALGORITMO GENÉTICO - FUNCIÓN ACKLEY
%
% Selección:
%   Torneo
%
% Cruce:
%   BLX-Alpha
%
% Mutación:
%   Mutación gaussiana sobre un gen
%
% Configuración:
%   - 100 iteraciones por defecto
%   - Varias pruebas independientes
%
% Se reporta:
%   - Mejor valor f(X)
%   - Mejor individuo X
%   - Tiempo
%   - Promedio de los mejores valores
%   - RMSE respecto al óptimo teórico
%
% NO se reporta desviación estándar.
% ============================================================


%% ============================================================
% VALORES POR DEFECTO
% ============================================================

if nargin < 1 || isempty(nPoblacion)
    nPoblacion = 20;
end

if nargin < 2 || isempty(nDimensiones)
    nDimensiones = 5;
end

if nargin < 3 || isempty(nIteraciones)
    nIteraciones = 100;
end

if nargin < 4 || isempty(nPruebas)
    nPruebas = 5;
end

if nargin < 5 || isempty(alpha)
    alpha = 0.5;
end

if nargin < 6 || isempty(probMutacion)
    probMutacion = 0.50;
end

if nargin < 7 || isempty(desviacion)
    desviacion = 0.10;
end 


%% ============================================================
% VALIDACIÓN DE PARÁMETROS
% ============================================================

validateattributes(nPoblacion, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(nDimensiones, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(nIteraciones, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(nPruebas, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(alpha, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'nonnegative'});

validateattributes(probMutacion, {'numeric'}, ...
    {'scalar', 'real', 'finite', '>=', 0, '<=', 1});

validateattributes(desviacion, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'nonnegative'});


if mod(nPoblacion, 2) ~= 0
    error('El tamaño de la población debe ser par.');
end


%% ============================================================
% PARÁMETROS DEL PROBLEMA
% ============================================================

limites = [-10, 10];

% Óptimo teórico de la Ackley modificada:
%
% Ackley original:
%       f(X) = 0
%
% En este proyecto se sumaron 3 unidades:
%       f(X) = Ackley(X) + 3
%
% Por lo tanto:
%       f_optimo = 3
%
% IMPORTANTE:
% Si se utiliza la función que aparece en el código proporcionado,
% el mínimo es 3, no 3-exp(1).

valorOptimoTeorico = 3;


%% ============================================================
% RESERVAR MEMORIA
% ============================================================

% Mejor valor encontrado en cada prueba
mejoresValores = zeros(nPruebas, 1);

% Mejor individuo encontrado en cada prueba
mejoresIndividuos = zeros(nPruebas, nDimensiones);

% Tiempo de ejecución de cada prueba
tiempos = zeros(nPruebas, 1);

% Mejor valor de cada iteración
mejoresIteraciones = zeros(nIteraciones, nPruebas);


%% ============================================================
% EJECUCIÓN DE LAS PRUEBAS
% ============================================================

for prueba = 1:nPruebas

    fprintf('\n============================================================\n');
    fprintf('ALGORITMO GENÉTICO - ACKLEY\n');
    fprintf('SELECCIÓN: TORNEO\n');
    fprintf('CRUCE: BLX-ALPHA\n');
    fprintf('MUTACIÓN: GAUSSIANA\n');
    fprintf('PRUEBA: %d de %d\n', prueba, nPruebas);
    fprintf('ITERACIONES: %d\n', nIteraciones);
    fprintf('PROBABILIDAD DE MUTACIÓN: %.2f\n', probMutacion);
    fprintf('DESVIACIÓN DE MUTACIÓN: %.2f\n', desviacion);
    fprintf('============================================================\n');


    tic;


    %% ========================================================
    % 1. GENERACIÓN DE POBLACIÓN INICIAL
    % ========================================================

    poblacion = generarPoblacionInicial( ...
        nPoblacion, ...
        nDimensiones, ...
        limites);


    %% ========================================================
    % 2. EVALUACIÓN INICIAL
    % ========================================================

    aptitud = arrayfun(@(i) ...
        ackleyFcn(poblacion(i, :)), ...
        (1:nPoblacion).');


    %% ========================================================
    % MEJOR SOLUCIÓN INICIAL
    % ========================================================

    [mejorValor, indiceMejor] = min(aptitud);

    mejorIndividuo = poblacion(indiceMejor, :);


    %% ========================================================
    % 3. ITERACIONES DEL ALGORITMO GENÉTICO
    % ========================================================

    for iteracion = 1:nIteraciones


        %% ====================================================
        % SELECCIÓN POR TORNEO
        % ====================================================

        [padres, ~] = seleccionTorneo( ...
            poblacion, ...
            aptitud, ...
            4, ...       % Tamaño del torneo
            2, ...       % Número de ganadores
            'min');


        %% ====================================================
        % CRUCE BLX-ALPHA
        % ====================================================

        nPadres = size(padres, 1);

        hijos = zeros(nPadres, nDimensiones);


        for i = 1:2:nPadres

            padre1 = padres(i, :);
            padre2 = padres(i + 1, :);

            [hijo1, hijo2] = ...
                cruceBLXAlpha( ...
                padre1, ...
                padre2, ...
                alpha);

            hijos(i, :) = hijo1;
            hijos(i + 1, :) = hijo2;

        end


        %% ====================================================
        % MUTACIÓN
        % ====================================================
        %
        % Cada hijo tiene una probabilidad probMutacion
        % de ser mutado.
        %
        % La función mutacionAckley modifica un solo gen
        % utilizando una perturbación gaussiana.
        %
        % La mutación respeta los límites [-10,10].
        % ====================================================

        for i = 1:nPadres

            if rand < probMutacion

                hijos(i, :) = mutacionAckley( ...
                    hijos(i, :), ...
                    desviacion, ...
                    limites);

            end

        end


        %% ====================================================
        % FORMACIÓN DE LA NUEVA POBLACIÓN
        % ====================================================

        poblacionNueva = [padres; hijos];


        %% ====================================================
        % VERIFICAR TAMAÑO DE LA POBLACIÓN
        % ====================================================

        if size(poblacionNueva, 1) ~= nPoblacion

            error(['La nueva población contiene %d individuos. ', ...
                'Se esperaban %d.'], ...
                size(poblacionNueva, 1), ...
                nPoblacion);

        end


        %% ====================================================
        % ACTUALIZAR POBLACIÓN
        % ====================================================

        poblacion = poblacionNueva;


        %% ====================================================
        % EVALUACIÓN DE LA NUEVA POBLACIÓN
        % ========================================================

        aptitud = arrayfun(@(i) ...
            ackleyFcn(poblacion(i, :)), ...
            (1:nPoblacion).');


        %% ====================================================
        % MEJOR RESULTADO DE LA ITERACIÓN
        % ====================================================

        [mejorValorIteracion, indiceMejorIteracion] = ...
            min(aptitud);


        mejoresIteraciones(iteracion, prueba) = ...
            mejorValorIteracion;


        %% ====================================================
        % ACTUALIZAR MEJOR SOLUCIÓN GLOBAL
        % ====================================================

        if mejorValorIteracion < mejorValor

            mejorValor = mejorValorIteracion;

            mejorIndividuo = ...
                poblacion(indiceMejorIteracion, :);

        end

    end


    %% ========================================================
    % TIEMPO DE EJECUCIÓN
    % ========================================================

    tiempoEjecucion = toc;


    %% ========================================================
    % GUARDAR RESULTADOS DE LA PRUEBA
    % ========================================================

    tiempos(prueba) = tiempoEjecucion;

    mejoresValores(prueba) = mejorValor;

    mejoresIndividuos(prueba, :) = ...
        mejorIndividuo;


    %% ========================================================
    % MOSTRAR RESULTADOS DE LA PRUEBA
    % ========================================================

    fprintf('\n---------------------------------------------\n');
    fprintf('RESULTADOS DE LA PRUEBA %d\n', prueba);
    fprintf('---------------------------------------------\n');

    fprintf('Tiempo de ejecución: %.6f segundos\n', ...
        tiempoEjecucion);

    fprintf('Mejor valor f(X): %.10f\n', ...
        mejorValor);

    fprintf('Mejor individuo X:\n');

    disp(mejorIndividuo);

end


%% ============================================================
% ESTADÍSTICAS GENERALES
% ============================================================

% Promedio de los mejores resultados de las pruebas

promedio = mean(mejoresValores);


%% ============================================================
% RMSE
% ============================================================
%
% RMSE = sqrt(
%     mean(
%         (f(X) - f_optimo)^2
%     )
% )
%
% Se calcula utilizando el mejor resultado de cada prueba.
% ============================================================

errores = ...
    mejoresValores - valorOptimoTeorico;

RMSE = sqrt(mean(errores.^2));


%% ============================================================
% TIEMPO PROMEDIO
% ============================================================

tiempoPromedio = mean(tiempos);


%% ============================================================
% MEJOR RESULTADO GLOBAL
% ============================================================

[mejorResultado, indiceMejorPrueba] = ...
    min(mejoresValores);


mejorIndividuoFinal = ...
    mejoresIndividuos(indiceMejorPrueba, :);


%% ============================================================
% GUARDAR RESULTADOS
% ============================================================

resultados.seleccion = 'Torneo';

resultados.cruce = 'BLX-Alpha';

resultados.mutacion = 'Gaussiana';

resultados.nPoblacion = nPoblacion;

resultados.nDimensiones = nDimensiones;

resultados.nIteraciones = nIteraciones;

resultados.nPruebas = nPruebas;

resultados.alpha = alpha;

resultados.probMutacion = probMutacion;

resultados.desviacionMutacion = desviacion;

resultados.valorOptimoTeorico = ...
    valorOptimoTeorico;


%% ============================================================
% DATOS INDIVIDUALES DE CADA PRUEBA
% ============================================================

resultados.pruebas = struct();


for prueba = 1:nPruebas

    resultados.pruebas(prueba).numero = ...
        prueba;

    resultados.pruebas(prueba).tiempo = ...
        tiempos(prueba);

    resultados.pruebas(prueba).mejorValor = ...
        mejoresValores(prueba);

    resultados.pruebas(prueba).mejorIndividuo = ...
        mejoresIndividuos(prueba, :);

    resultados.pruebas(prueba).mejoresIteraciones = ...
        mejoresIteraciones(:, prueba);

end


%% ============================================================
% ESTADÍSTICAS GENERALES
% ============================================================

resultados.tiempoPromedio = ...
    tiempoPromedio;

resultados.promedio = ...
    promedio;

resultados.mejorValor = ...
    mejorResultado;

resultados.mejorIndividuo = ...
    mejorIndividuoFinal;

resultados.RMSE = ...
    RMSE;

resultados.mejoresPruebas = ...
    mejoresValores;

resultados.tiemposPruebas = ...
    tiempos;

resultados.mejoresIndividuos = ...
    mejoresIndividuos;

resultados.mejoresIteraciones = ...
    mejoresIteraciones;


%% ============================================================
% TABLA POR PRUEBA
% ============================================================

tablaPruebas = table( ...
    (1:nPruebas).', ...
    tiempos, ...
    mejoresValores, ...
    mejoresIndividuos, ...
    'VariableNames', { ...
    'Prueba', ...
    'Tiempo_s', ...
    'Mejor_fX', ...
    'Mejor_X'});


resultados.tablaPruebas = ...
    tablaPruebas;


%% ============================================================
% TABLA RESUMEN GENERAL
% ============================================================

tablaResumen = table( ...
    tiempoPromedio, ...
    promedio, ...
    mejorResultado, ...
    mejorIndividuoFinal, ...
    RMSE, ...
    'VariableNames', { ...
    'TiempoPromedio_s', ...
    'Promedio_fX', ...
    'Mejor_fX', ...
    'Mejor_X', ...
    'RMSE'});


resultados.tablaResumen = ...
    tablaResumen;


%% ============================================================
% MOSTRAR RESULTADOS POR PRUEBA
% ============================================================

fprintf('\n\n============================================================\n');
fprintf('RESULTADOS POR PRUEBA\n');
fprintf('============================================================\n');

fprintf('%-10s %-15s %-20s\n', ...
    'Prueba', ...
    'Tiempo (s)', ...
    'Mejor f(X)');

fprintf('------------------------------------------------------------\n');


for prueba = 1:nPruebas

    fprintf('%-10d %-15.6f %-20.10f\n', ...
        prueba, ...
        tiempos(prueba), ...
        mejoresValores(prueba));

end


%% ============================================================
% MOSTRAR RESULTADOS GENERALES
% ============================================================

fprintf('\n============================================================\n');
fprintf('RESULTADOS GENERALES\n');
fprintf('============================================================\n');

fprintf('Método de selección: Torneo\n');
fprintf('Cruce: BLX-Alpha\n');
fprintf('Mutación: Gaussiana\n');
fprintf('Población: %d\n', nPoblacion);
fprintf('Dimensiones: %d\n', nDimensiones);
fprintf('Iteraciones: %d\n', nIteraciones);
fprintf('Pruebas: %d\n', nPruebas);
fprintf('Alpha: %.4f\n', alpha);
fprintf('Probabilidad de mutación: %.4f\n', probMutacion);
fprintf('Desviación de mutación: %.4f\n', desviacion);

fprintf('------------------------------------------------------------\n');

fprintf('Tiempo promedio: %.6f segundos\n', ...
    tiempoPromedio);

fprintf('Promedio de los mejores f(X): %.10f\n', ...
    promedio);

fprintf('Mejor f(X) global: %.10f\n', ...
    mejorResultado);

fprintf('Prueba que obtuvo el mejor resultado: %d\n', ...
    indiceMejorPrueba);

fprintf('RMSE: %.10f\n', ...
    RMSE);

fprintf('\nMejor individuo X:\n');

disp(mejorIndividuoFinal);

fprintf('============================================================\n');


%% ============================================================
% MOSTRAR TABLA DE RESULTADOS
% ============================================================

fprintf('\n============================================================\n');
fprintf('TABLA RESUMEN\n');
fprintf('============================================================\n');

disp(tablaResumen);


end

%{
function resultados = pruebaAckleyDimensiones( ...
        nPoblacion, dimensiones, nIteraciones, nPruebas, alpha)

% ============================================================
% PRUEBA DEL ALGORITMO GENÉTICO - FUNCIÓN ACKLEY
%
% OBJETIVO:
%   Evaluar el efecto del número de dimensiones sobre el desempeño
%   del algoritmo genético.
%
% MÉTODO DE SELECCIÓN:
%   Torneo
%
% CRUCE:
%   BLX-Alpha
%
% MUTACIÓN:
%   No se aplica
%
% DIMENSIONES EVALUADAS:
%   2, 3, 10, 20, 50 y 100
%
% MÉTRICAS:
%   - Tiempo de ejecución
%   - Mejor f(X)
%   - Mejor individuo X
%   - Promedio de los mejores resultados
%   - RMSE respecto al óptimo teórico
%
% NO SE REPORTA DESVIACIÓN ESTÁNDAR.
% ============================================================


%% ============================================================
% VALORES POR DEFECTO
% ============================================================

if nargin < 1 || isempty(nPoblacion)
    nPoblacion = 20;
end

if nargin < 2 || isempty(dimensiones)
    dimensiones = [2 3 10 20 50 100];
end

if nargin < 3 || isempty(nIteraciones)
    nIteraciones = 100;
end

if nargin < 4 || isempty(nPruebas)
    nPruebas = 5;
end

if nargin < 5 || isempty(alpha)
    alpha = 0.5;
end


%% ============================================================
% VALIDACIÓN DE PARÁMETROS
% ============================================================

validateattributes(nPoblacion, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(dimensiones, {'numeric'}, ...
    {'vector', 'integer', 'positive'});

validateattributes(nIteraciones, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(nPruebas, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(alpha, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'nonnegative'});


if mod(nPoblacion, 2) ~= 0
    error('El tamaño de la población debe ser par.');
end


%% ============================================================
% PARÁMETROS DEL PROBLEMA
% ============================================================

limites = [-10, 10];
valorOptimoTeorico = 3 - exp(1);


%% ============================================================
% NÚMERO DE ESCENARIOS
% ============================================================

nDimensiones = numel(dimensiones);


%% ============================================================
% RESERVAR MEMORIA
% ============================================================

% Mejor valor encontrado en cada prueba
mejoresValores = zeros(nDimensiones, nPruebas);

% Mejor individuo encontrado en cada prueba
% Cada escenario puede tener diferente número de dimensiones,
% por lo que se utiliza una celda.
mejoresIndividuos = cell(nDimensiones, nPruebas);

% Tiempo de cada prueba
tiempos = zeros(nDimensiones, nPruebas);

% Mejor valor de cada iteración
mejoresIteraciones = cell(nDimensiones, nPruebas);


%% ============================================================
% EJECUCIÓN DE LOS ESCENARIOS
% ============================================================

for escenario = 1:nDimensiones

    d = dimensiones(escenario);

    fprintf('\n\n');
    fprintf('============================================================\n');
    fprintf('ESCENARIO DE DIMENSIONES: %d\n', d);
    fprintf('============================================================\n');


    %% ========================================================
    % PRUEBAS INDEPENDIENTES
    % ========================================================

    for prueba = 1:nPruebas

        fprintf('\n---------------------------------------------\n');
        fprintf('Dimensiones: %d | Prueba: %d de %d\n', ...
            d, prueba, nPruebas);
        fprintf('---------------------------------------------\n');


        tic;


        %% ====================================================
        % 1. GENERACIÓN DE POBLACIÓN INICIAL
        % ====================================================

        poblacion = generarPoblacionInicial( ...
            nPoblacion, ...
            d, ...
            limites);


        %% ====================================================
        % 2. EVALUACIÓN INICIAL
        % ====================================================

        aptitud = arrayfun(@(i) ...
            ackleyFcn(poblacion(i, :)), ...
            (1:nPoblacion).');


        %% ====================================================
        % MEJOR SOLUCIÓN INICIAL
        % ====================================================

        [mejorValor, indiceMejor] = min(aptitud);

        mejorIndividuo = poblacion(indiceMejor, :);


        %% ====================================================
        % RESERVAR HISTORIAL DE LA PRUEBA
        % ====================================================

        mejoresIteracionesActual = ...
            zeros(nIteraciones, 1);


        %% ====================================================
        % 3. ITERACIONES DEL ALGORITMO GENÉTICO
        % ====================================================

        for iteracion = 1:nIteraciones


            %% ==================================================
            % SELECCIÓN POR TORNEO
            % ==================================================

            [padres, ~] = seleccionTorneo( ...
                poblacion, ...
                aptitud, ...
                4, ...       % Tamaño del torneo
                2, ...       % Número de ganadores
                'min');


            %% ==================================================
            % CRUCE BLX-ALPHA
            % ==================================================

            nPadres = size(padres, 1);

            hijos = zeros(nPadres, d);


            for i = 1:2:nPadres

                padre1 = padres(i, :);
                padre2 = padres(i + 1, :);


                [hijo1, hijo2] = cruceBLXAlpha( ...
                    padre1, ...
                    padre2, ...
                    alpha);


                hijos(i, :) = hijo1;
                hijos(i + 1, :) = hijo2;

            end


            %% ==================================================
            % FORMACIÓN DE LA NUEVA POBLACIÓN
            % ==================================================

            poblacionNueva = [padres; hijos];


            %% ==================================================
            % VERIFICACIÓN DEL TAMAÑO
            % ==================================================

            if size(poblacionNueva, 1) ~= nPoblacion

                error(['La nueva población contiene %d individuos. ', ...
                    'Se esperaban %d.'], ...
                    size(poblacionNueva, 1), ...
                    nPoblacion);

            end


            %% ==================================================
            % ACTUALIZAR POBLACIÓN
            % ==================================================

            poblacion = poblacionNueva;


            %% ==================================================
            % EVALUACIÓN DE LA NUEVA POBLACIÓN
            % ==================================================

            aptitud = arrayfun(@(i) ...
                ackleyFcn(poblacion(i, :)), ...
                (1:nPoblacion).');


            %% ==================================================
            % MEJOR RESULTADO DE LA ITERACIÓN
            % ==================================================

            [mejorValorIteracion, indiceMejorIteracion] = ...
                min(aptitud);


            mejoresIteracionesActual(iteracion) = ...
                mejorValorIteracion;


            %% ==================================================
            % ACTUALIZAR MEJOR SOLUCIÓN GLOBAL
            % ==================================================

            if mejorValorIteracion < mejorValor

                mejorValor = mejorValorIteracion;

                mejorIndividuo = ...
                    poblacion(indiceMejorIteracion, :);

            end

        end


        %% ====================================================
        % TIEMPO DE EJECUCIÓN
        % ====================================================

        tiempoEjecucion = toc;


        %% ====================================================
        % GUARDAR RESULTADOS DE LA PRUEBA
        % ====================================================

        tiempos(escenario, prueba) = ...
            tiempoEjecucion;

        mejoresValores(escenario, prueba) = ...
            mejorValor;

        mejoresIndividuos{escenario, prueba} = ...
            mejorIndividuo;

        mejoresIteraciones{escenario, prueba} = ...
            mejoresIteracionesActual;


        %% ====================================================
        % MOSTRAR RESULTADOS DE LA PRUEBA
        % ====================================================

        fprintf('Tiempo de ejecución: %.6f segundos\n', ...
            tiempoEjecucion);

        fprintf('Mejor valor f(X): %.10f\n', ...
            mejorValor);

        fprintf('Mejor individuo X:\n');

        disp(mejorIndividuo);

    end


    %% ========================================================
    % ESTADÍSTICAS DEL ESCENARIO
    % ========================================================

    valoresEscenario = ...
        mejoresValores(escenario, :);


    %% ========================================================
    % PROMEDIO
    % ========================================================

    promedio = mean(valoresEscenario);


    %% ========================================================
    % RMSE
    % ========================================================
    %
    % RMSE = sqrt(
    %     mean(
    %         (f(X) - f_optimo)^2
    %     )
    % )
    %
    % Se utilizan los mejores resultados obtenidos
    % en cada prueba independiente.
    %
    % ========================================================

    errores = ...
        valoresEscenario - valorOptimoTeorico;

    RMSE = sqrt(mean(errores.^2));


    %% ========================================================
    % TIEMPO PROMEDIO
    % ========================================================

    tiempoPromedio = ...
        mean(tiempos(escenario, :));


    %% ========================================================
    % MEJOR RESULTADO GLOBAL DEL ESCENARIO
    % ========================================================

    [mejorResultado, indiceMejorPrueba] = ...
        min(valoresEscenario);


    %% ========================================================
    % MEJOR INDIVIDUO DEL ESCENARIO
    % ========================================================

    mejorIndividuoFinal = ...
        mejoresIndividuos{escenario, indiceMejorPrueba};


    %% ========================================================
    % GUARDAR RESULTADOS DEL ESCENARIO
    % ========================================================

    resultados(escenario).dimensiones = d;

    resultados(escenario).seleccion = ...
        'Torneo';

    resultados(escenario).cruce = ...
        'BLX-Alpha';

    resultados(escenario).alpha = ...
        alpha;

    resultados(escenario).nPoblacion = ...
        nPoblacion;

    resultados(escenario).nIteraciones = ...
        nIteraciones;

    resultados(escenario).nPruebas = ...
        nPruebas;

    resultados(escenario).valorOptimoTeorico = ...
        valorOptimoTeorico;


    %% ========================================================
    % DATOS DE CADA PRUEBA
    % ========================================================

    resultados(escenario).pruebas = struct();


    for prueba = 1:nPruebas

        resultados(escenario).pruebas(prueba).numero = ...
            prueba;

        resultados(escenario).pruebas(prueba).tiempo = ...
            tiempos(escenario, prueba);

        resultados(escenario).pruebas(prueba).mejorValor = ...
            mejoresValores(escenario, prueba);

        resultados(escenario).pruebas(prueba).mejorIndividuo = ...
            mejoresIndividuos{escenario, prueba};

        resultados(escenario).pruebas(prueba).mejoresIteraciones = ...
            mejoresIteraciones{escenario, prueba};

    end


    %% ========================================================
    % ESTADÍSTICAS GENERALES DEL ESCENARIO
    % ========================================================

    resultados(escenario).tiempoPromedio = ...
        tiempoPromedio;

    resultados(escenario).promedio = ...
        promedio;

    resultados(escenario).mejorValor = ...
        mejorResultado;

    resultados(escenario).mejorIndividuo = ...
        mejorIndividuoFinal;

    resultados(escenario).RMSE = ...
        RMSE;

    resultados(escenario).mejoresPruebas = ...
        valoresEscenario;

    resultados(escenario).tiemposPruebas = ...
        tiempos(escenario, :);


    %% ========================================================
    % MOSTRAR RESUMEN DEL ESCENARIO
    % ========================================================

    fprintf('\n============================================================\n');
    fprintf('RESUMEN - %d DIMENSIONES\n', d);
    fprintf('============================================================\n');

    fprintf('Tiempo promedio: %.6f segundos\n', ...
        tiempoPromedio);

    fprintf('Promedio de los mejores f(X): %.10f\n', ...
        promedio);

    fprintf('RMSE: %.10f\n', ...
        RMSE);

    fprintf('Mejor resultado global: %.10f\n', ...
        mejorResultado);

    fprintf('Prueba con mejor resultado: %d\n', ...
        indiceMejorPrueba);

    fprintf('Mejor individuo X:\n');

    disp(mejorIndividuoFinal);

end


%% ============================================================
% TABLA RESUMEN GENERAL
% ============================================================

tiempoPromedioTabla = zeros(nDimensiones, 1);
promedioTabla = zeros(nDimensiones, 1);
mejorValorTabla = zeros(nDimensiones, 1);
RMSETabla = zeros(nDimensiones, 1);

mejoresIndividuosTabla = cell(nDimensiones, 1);


for escenario = 1:nDimensiones

    tiempoPromedioTabla(escenario) = ...
        resultados(escenario).tiempoPromedio;

    promedioTabla(escenario) = ...
        resultados(escenario).promedio;

    mejorValorTabla(escenario) = ...
        resultados(escenario).mejorValor;

    RMSETabla(escenario) = ...
        resultados(escenario).RMSE;

    mejoresIndividuosTabla{escenario} = ...
        resultados(escenario).mejorIndividuo;

end


tablaResumen = table( ...
    dimensiones(:), ...
    tiempoPromedioTabla, ...
    promedioTabla, ...
    mejorValorTabla, ...
    RMSETabla, ...
    mejoresIndividuosTabla, ...
    'VariableNames', { ...
    'Dimensiones', ...
    'TiempoPromedio_s', ...
    'Promedio_fX', ...
    'Mejor_fX', ...
    'RMSE', ...
    'Mejor_X'});


%% ============================================================
% GUARDAR TABLA EN LOS RESULTADOS
% ============================================================

resultados(1).tablaResumen = ...
    tablaResumen;


%% ============================================================
% MOSTRAR TABLA GENERAL
% ============================================================

fprintf('\n\n');
fprintf('======================================================================\n');
fprintf('              RESULTADOS FINALES - ACKLEY\n');
fprintf('======================================================================\n');

fprintf('Selección: Torneo\n');
fprintf('Cruce: BLX-Alpha\n');
fprintf('Alpha: %.4f\n', alpha);
fprintf('Población: %d\n', nPoblacion);
fprintf('Iteraciones: %d\n', nIteraciones);
fprintf('Pruebas por escenario: %d\n', nPruebas);
fprintf('Óptimo teórico: %.10f\n', valorOptimoTeorico);

fprintf('----------------------------------------------------------------------\n');

fprintf('%-12s %-18s %-18s %-18s %-18s\n', ...
    'Dimensiones', ...
    'Tiempo prom. (s)', ...
    'Promedio f(X)', ...
    'Mejor f(X)', ...
    'RMSE');

fprintf('----------------------------------------------------------------------\n');


for escenario = 1:nDimensiones

    fprintf('%-12d %-18.6f %-18.10f %-18.10f %-18.10f\n', ...
        dimensiones(escenario), ...
        tiempoPromedioTabla(escenario), ...
        promedioTabla(escenario), ...
        mejorValorTabla(escenario), ...
        RMSETabla(escenario));

end


fprintf('======================================================================\n');


%% ============================================================
% MOSTRAR TABLA MATLAB
% ============================================================

fprintf('\n============================================================\n');
fprintf('TABLA RESUMEN\n');
fprintf('============================================================\n');

disp(tablaResumen);


%% ============================================================
% MOSTRAR MEJORES INDIVIDUOS
% ============================================================

fprintf('\n============================================================\n');
fprintf('MEJORES INDIVIDUOS POR NÚMERO DE DIMENSIONES\n');
fprintf('============================================================\n');


for escenario = 1:nDimensiones

    fprintf('\nDimensiones: %d\n', ...
        dimensiones(escenario));

    fprintf('Mejor f(X): %.10f\n', ...
        mejorValorTabla(escenario));

    fprintf('Mejor individuo X:\n');

    disp(mejoresIndividuosTabla{escenario});

end


end
%}

% FUNCIÓN OBJETIVO DE ACKLEY
function valor = ackleyFcn(X)

validateattributes(X, {'numeric'}, ...
    {'vector', 'nonempty', 'real', 'finite'});

if any(X < -10 | X > 10)
    valor = 1e6;
    return;
end

X = X(:);

valor = -20 * exp(-0.2 * sqrt(mean(X.^2))) ...
    - exp(mean(cos(2 * pi * X))) ...
    + 20 + 3; % Ajuste para evitar que el minimo de un resultado de 0

end

function poblacion = generarPoblacionInicial(n, d, limites)

validateattributes(n, {'numeric'}, {'scalar', 'integer', 'positive'});
validateattributes(d, {'numeric'}, {'scalar', 'integer', 'positive'});
validateattributes(limites, {'numeric'}, {'vector', 'numel', 2, 'real', 'finite'});

limiteInferior = min(limites);
limiteSuperior = max(limites);

poblacion = limiteInferior + ...
    (limiteSuperior - limiteInferior) .* rand(n, d);

end

function [elite, indices] = seleccionElitismo(poblacion, aptitud, nElite)

    if nargin < 3
        nElite = 1;
    end

    validateattributes(nElite, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    nElite = min(nElite, size(poblacion, 1));

    if isa(aptitud, 'function_handle')
        valores = arrayfun(@(i) aptitud(poblacion(i, :)), ...
            (1:size(poblacion, 1)).');
    else
        valores = aptitud(:);
    end

    if numel(valores) ~= size(poblacion, 1) || any(~isfinite(valores))
        error('La aptitud debe contener un valor finito por individuo.');
    end

    [~, orden] = sort(valores, 'ascend');
    indices = orden(1:nElite);
    elite = poblacion(indices, :);

end

function [seleccion, indices] = seleccionTorneo(poblacion, aptitud, tamTorneo, nGanadores, objetivo)

    validateattributes(poblacion, {'numeric'}, ...
        {'2d', 'nonempty'});

    n = size(poblacion, 1);

    if nargin < 3 || isempty(tamTorneo)
        tamTorneo = 4;
    end

    if nargin < 4 || isempty(nGanadores)
        nGanadores = 2;
    end

    if nargin < 5 || isempty(objetivo)
        objetivo = 'min';
    end

    validateattributes(tamTorneo, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    validateattributes(nGanadores, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    if nGanadores > tamTorneo
        error('No se pueden seleccionar más ganadores que individuos del grupo.');
    end

    if mod(n, tamTorneo) ~= 0
        error(['El tamaño de la población debe ser múltiplo del ', ...
               'tamaño del torneo.']);
    end

    if nGanadores * (n / tamTorneo) ~= n / 2
        error(['La configuración debe producir exactamente la mitad ', ...
               'de la población.']);
    end

    if isa(aptitud, 'function_handle')

        valores = arrayfun(@(i) ...
            aptitud(poblacion(i, :)), ...
            (1:n).');

    else

        valores = aptitud(:);

    end

    if numel(valores) ~= n || any(~isfinite(valores))
        error('La aptitud debe contener un valor finito por individuo.');
    end

    % ============================================================
    % SELECCIÓN ALEATORIA SIN REEMPLAZO
    % ============================================================

    ordenAleatorio = randperm(n);

    nGrupos = n / tamTorneo;

    indices = zeros(nGrupos * nGanadores, 1);

    posicionSalida = 1;

    for grupo = 1:nGrupos

        % Individuos que pertenecen al grupo actual
        inicio = (grupo - 1) * tamTorneo + 1;
        fin = grupo * tamTorneo;

        grupoIndices = ordenAleatorio(inicio:fin);

        % Aptitudes de los individuos del grupo
        aptitudesGrupo = valores(grupoIndices);

        % Seleccionar los mejores
        switch lower(char(objetivo))

            case 'min'

                [~, orden] = sort(aptitudesGrupo, 'ascend');

            case 'max'

                [~, orden] = sort(aptitudesGrupo, 'descend');

            otherwise

                error('El objetivo debe ser ''min'' o ''max''.');

        end

        ganadores = grupoIndices(orden(1:nGanadores));

        indices(posicionSalida:posicionSalida+nGanadores-1) = ...
            ganadores(:);

        posicionSalida = posicionSalida + nGanadores;

    end

    seleccion = poblacion(indices, :);

end

function [seleccion, indices, probabilidades] = seleccionRuleta( ...
        poblacion, aptitud, nSeleccion)

    validateattributes(poblacion, {'numeric'}, ...
        {'2d', 'nonempty'});

    n = size(poblacion, 1);

    if nargin < 3 || isempty(nSeleccion)
        nSeleccion = n;
    end

    validateattributes(nSeleccion, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    if isa(aptitud, 'function_handle')

        valores = arrayfun(@(i) ...
            aptitud(poblacion(i, :)), ...
            (1:n).');

    else

        valores = aptitud(:);

    end

    if numel(valores) ~= n || any(~isfinite(valores))
        error('La aptitud debe contener un valor finito por individuo.');
    end

    if any(valores <= 0)
        error(['Para la selección por ruleta de minimización, ', ...
               'la aptitud debe ser mayor que cero.']);
    end

    % Probabilidad inversamente proporcional al fitness
    pesos = 1 ./ valores;

    probabilidades = pesos ./ sum(pesos);

    % Ruleta acumulada
    acumuladas = cumsum(probabilidades);

    % Selección de individuos
    indices = arrayfun(@(x) ...
        find(acumuladas >= x, 1, 'first'), ...
        rand(nSeleccion, 1));

    seleccion = poblacion(indices, :);

end

function [hijo1, hijo2] = cruceBLXAlpha(padre1, padre2, alpha)

if nargin < 3 || isempty(alpha)
    alpha = 0.5;
end

validateattributes(padre1, {'numeric'}, {'vector', 'real', 'finite'});
validateattributes(padre2, {'numeric'}, {'vector', 'real', 'finite'});
validateattributes(alpha, {'numeric'}, {'scalar', 'real', 'finite', 'nonnegative'});

if numel(padre1) ~= numel(padre2)
    error('Los padres deben tener la misma longitud.');
end

padre1 = padre1(:).';
padre2 = padre2(:).';

inferior = min(padre1, padre2);
superior = max(padre1, padre2);
distancia = superior - inferior;

limiteInferior = inferior - alpha .* distancia;
limiteSuperior = superior + alpha .* distancia;

hijo1 = limiteInferior + rand(size(padre1)) .* ...
    (limiteSuperior - limiteInferior);
hijo2 = limiteInferior + rand(size(padre1)) .* ...
    (limiteSuperior - limiteInferior);

hijo1 = min(max(hijo1, -10), 10);
hijo2 = min(max(hijo2, -10), 10);

end

function [individuoMutado, indice] = mutacionAckley(individuo, desviacion, limites)

if nargin < 2 || isempty(desviacion)
    desviacion = 0.10;
end
if nargin < 3 || isempty(limites)
    limites = [-10, 10];
end

validateattributes(individuo, {'numeric'}, ...
    {'vector', 'nonempty', 'real', 'finite'});
validateattributes(desviacion, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'nonnegative'});
validateattributes(limites, {'numeric'}, ...
    {'vector', 'numel', 2, 'real', 'finite'});

limiteInferior = min(limites);
limiteSuperior = max(limites);

indice = randi(numel(individuo));
individuoMutado = individuo;
individuoMutado(indice) = individuo(indice) + desviacion * randn;
individuoMutado(indice) = min(max(individuoMutado(indice), ...
    limiteInferior), limiteSuperior);

end

