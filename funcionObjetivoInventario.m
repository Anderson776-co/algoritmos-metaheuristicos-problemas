%{
function resultados = pruebaAlgoritmoGeneticoInventario( ...
    nPoblacion, nIteraciones, nPruebas, alpha)

% ==============================================================
% PRUEBA DEL ALGORITMO GENÉTICO - PROBLEMA DE INVENTARIO
%
% Métodos de selección:
%   1. Elitismo
%   2. Torneo
%   3. Ruleta
%
% Cruce:
%   BLX-alpha
%
% Objetivo:
%   Minimizar la función fitnessInventario
%
% ===============================================================

% Valores por defecto
if nargin < 1 || isempty(nPoblacion)
    nPoblacion = 48;
end

if nargin < 2 || isempty(nIteraciones)
    nIteraciones = 100;
end

if nargin < 3 || isempty(nPruebas)
    nPruebas = 5;
end

if nargin < 4 || isempty(alpha)
    alpha = 0.5;
end

% ==============================================================
% VALIDACIONES
% ==============================================================

validateattributes(nPoblacion, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(nIteraciones, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(nPruebas, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(alpha, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'nonnegative'});

if mod(nPoblacion, 4) ~= 0
    error('El tamaño de la población debe ser múltiplo de 4.');
end

% ==============================================================
% LIMITES DE LAS VARIABLES
%
% Individuo:
%
% [Q1 Q2 Q3 Q4 Q5 S1 S2 S3 S4 S5 K1 K2 K3 K4 K5]
% ==============================================================

limiteInferior = [ ...
    0     0     0     0     0 ...
    0     0     0     0     0 ...
    0     0     0     0     0];

limiteSuperior = [ ...
    12000 80000 150000 50000 100000 ...
    200   1200  2500   800    1500 ...
    500   2000  5000   1500   3000];

% ==============================================================
% VARIABLES PARA GUARDAR RESULTADOS
% ==============================================================

selecciones = {'Elitismo', 'Torneo', 'Ruleta'};

resultados = struct();

for metodo = 1:3

    nombreSeleccion = selecciones{metodo};

    tiemposPruebas = zeros(nPruebas, 1);
    mejoresPruebas = zeros(nPruebas, 1);
    mejoresIndividuos = zeros(nPruebas, 15);
    mejoresIteraciones = zeros(nIteraciones, nPruebas);

    % ==========================================================
    % PRUEBAS
    % ==========================================================

    fprintf('\n');
    fprintf('####################################################################\n');
    fprintf('                 SELECCIÓN: %s\n', upper(nombreSeleccion));
    fprintf('####################################################################\n');

    for prueba = 1:nPruebas

        fprintf('\n=============================================\n');
        fprintf('PRUEBA %d DE %d\n', prueba, nPruebas);
        fprintf('Selección: %s\n', nombreSeleccion);
        fprintf('Cruce: BLX-alpha\n');
        fprintf('Alpha: %.2f\n', alpha);
        fprintf('Iteraciones: %d\n', nIteraciones);
        fprintf('=============================================\n');

        % ------------------------------------------------------
        % Generar población inicial
        % ------------------------------------------------------

        poblacion = generarPoblacionInventario(nPoblacion);

        mejorValor = inf;
        mejorIndividuo = [];
        historialMejor = zeros(nIteraciones, 1);

        % ------------------------------------------------------
        % Inicio del tiempo
        % ------------------------------------------------------

        tic;

        % ======================================================
        % CICLO EVOLUTIVO
        % ======================================================

        for iteracion = 1:nIteraciones

            % --------------------------------------------------
            % Evaluar población
            % --------------------------------------------------

            aptitud = zeros(nPoblacion, 1);

            for i = 1:nPoblacion

                aptitud(i) = fitnessInventario( ...
                    poblacion(i,1:5), ...
                    poblacion(i,6:10), ...
                    poblacion(i,11:15));

            end

            % --------------------------------------------------
            % Guardar mejor individuo de la iteración
            % --------------------------------------------------

            [valorIteracion, indiceMejor] = min(aptitud);

            if valorIteracion < mejorValor

                mejorValor = valorIteracion;
                mejorIndividuo = poblacion(indiceMejor, :);

            end

            historialMejor(iteracion) = mejorValor;

            % --------------------------------------------------
            % Selección
            % --------------------------------------------------

            switch metodo

                case 1

                    % Elitismo:
                    % Se conserva la mitad de la población

                    [padres, ~] = seleccionElitismo( ...
                        poblacion, aptitud, nPoblacion/2);

                case 2

                    % Torneo:
                    % Grupos de 4 y 2 ganadores

                    [padres, ~] = seleccionTorneo( ...
                        poblacion, aptitud, 4, 2, 'min');

                case 3

                    % Ruleta:
                    % Se selecciona la mitad

                    [padres, ~, ~] = seleccionRuleta( ...
                        poblacion, aptitud, nPoblacion/2);

            end

            % --------------------------------------------------
            % Crear hijos mediante BLX-alpha
            % --------------------------------------------------

            hijos = zeros(nPoblacion/2, 15);

            contadorHijo = 1;

            for j = 1:2:size(padres,1)-1

                padre1 = padres(j,:);
                padre2 = padres(j+1,:);

                [hijo1, hijo2] = cruceBLXAlphaInventario( ...
                    padre1, padre2, alpha, ...
                    limiteInferior, limiteSuperior);

                % ----------------------------------------------
                % Reparar restricción de inventario
                % ----------------------------------------------

                hijo1 = repararInventario(hijo1);
                hijo2 = repararInventario(hijo2);

                hijos(contadorHijo,:) = hijo1;
                hijos(contadorHijo+1,:) = hijo2;

                contadorHijo = contadorHijo + 2;

            end

            % --------------------------------------------------
            % Nueva población
            % --------------------------------------------------

            poblacion = [padres; hijos];

        end

        % ======================================================
        % TIEMPO FINAL
        % ======================================================

        tiempo = toc;

        tiemposPruebas(prueba) = tiempo;
        mejoresPruebas(prueba) = mejorValor;
        mejoresIndividuos(prueba,:) = mejorIndividuo;
        mejoresIteraciones(:,prueba) = historialMejor;

        % ======================================================
        % RESULTADO DE LA PRUEBA
        % ======================================================

        fprintf('\nResultado de la prueba %d:\n', prueba);
        fprintf('Tiempo de ejecución: %.6f segundos\n', tiempo);
        fprintf('Mejor valor f(X): %.6f\n', mejorValor);

        fprintf('Mejor individuo X:\n');
        fprintf('Q: ');
        fprintf('%.6f ', mejorIndividuo(1:5));
        fprintf('\n');

        fprintf('S: ');
        fprintf('%.6f ', mejorIndividuo(6:10));
        fprintf('\n');

        fprintf('K: ');
        fprintf('%.6f ', mejorIndividuo(11:15));
        fprintf('\n');

    end

    % ==========================================================
    % RESULTADOS INDIVIDUALES
    % ==========================================================

    fprintf('\n\n====================================================================\n');
    fprintf('       RESULTADOS INDIVIDUALES - %s + BLX-alpha\n', ...
        upper(nombreSeleccion));
    fprintf('====================================================================\n');

    fprintf('%-8s %-18s %-18s\n', ...
        'Prueba', 'Tiempo (s)', 'Mejor f(X)');

    fprintf('--------------------------------------------------------------------\n');

    for prueba = 1:nPruebas

        fprintf('%-8d %-18.6f %-18.6f\n', ...
            prueba, ...
            tiemposPruebas(prueba), ...
            mejoresPruebas(prueba));

    end

    fprintf('====================================================================\n');

    % ==========================================================
    % MEJORES INDIVIDUOS
    % ==========================================================

    fprintf('\n====================================================================\n');
    fprintf('             MEJORES INDIVIDUOS EN CADA PRUEBA\n');
    fprintf('====================================================================\n');

    for prueba = 1:nPruebas

        fprintf('Prueba %d\n', prueba);

        fprintf('Mejor f(X): %.6f\n', ...
            mejoresPruebas(prueba));

        fprintf('Q: ');
        fprintf('%.6f ', mejoresIndividuos(prueba,1:5));
        fprintf('\n');

        fprintf('S: ');
        fprintf('%.6f ', mejoresIndividuos(prueba,6:10));
        fprintf('\n');

        fprintf('K: ');
        fprintf('%.6f ', mejoresIndividuos(prueba,11:15));
        fprintf('\n');

        fprintf('--------------------------------------------------------------------\n');

    end

    % ==========================================================
    % RESUMEN ESTADÍSTICO
    % ==========================================================

    tiempoPromedio = mean(tiemposPruebas);
    promedio = mean(mejoresPruebas);

    % Misma lógica utilizada en el ejemplo:
    % desviación estándar de los mejores resultados
    desviacionEstandar = std(mejoresPruebas);

    [mejorGlobal, pruebaMejor] = min(mejoresPruebas);

    individuoMejor = mejoresIndividuos(pruebaMejor,:);

    fprintf('\n====================================================================\n');
    fprintf('                    RESUMEN ESTADÍSTICO\n');
    fprintf('====================================================================\n');

    fprintf('Tiempo promedio:          %.6f segundos\n', ...
        tiempoPromedio);

    fprintf('Promedio mejor f(X):      %.6f\n', ...
        promedio);

    fprintf('Desviación estándar:      %.6f\n', ...
        desviacionEstandar);

    fprintf('Mejor f(X) global:        %.6f\n', ...
        mejorGlobal);

    fprintf('Prueba del mejor resultado: %d\n', ...
        pruebaMejor);

    fprintf('--------------------------------------------------------------------\n');

    fprintf('Individuo X del mejor resultado:\n');

    fprintf('Q: ');
    fprintf('%.6f ', individuoMejor(1:5));
    fprintf('\n');

    fprintf('S: ');
    fprintf('%.6f ', individuoMejor(6:10));
    fprintf('\n');

    fprintf('K: ');
    fprintf('%.6f ', individuoMejor(11:15));
    fprintf('\n');

    fprintf('\n====================================================================\n');
    fprintf('                         TABLA FINAL\n');
    fprintf('====================================================================\n');

    fprintf('Selección:                %s\n', nombreSeleccion);
    fprintf('Cruce:                    BLX-alpha\n');
    fprintf('Alpha:                    %.2f\n', alpha);
    fprintf('Iteraciones:              %d\n', nIteraciones);
    fprintf('Población:                %d\n', nPoblacion);
    fprintf('Número de pruebas:        %d\n', nPruebas);

    fprintf('\nMejor valor f(X):         %.6f\n', mejorGlobal);
    fprintf('Desviación estándar:      %.6f\n', desviacionEstandar);
    fprintf('Tiempo promedio:          %.6f s\n', tiempoPromedio);

    fprintf('====================================================================\n');

    % ==========================================================
    % GUARDAR RESULTADOS
    % ==========================================================

    resultados(metodo).seleccion = nombreSeleccion;
    resultados(metodo).cruce = 'BLX-alpha';
    resultados(metodo).alpha = alpha;
    resultados(metodo).nPoblacion = nPoblacion;
    resultados(metodo).nIteraciones = nIteraciones;
    resultados(metodo).nPruebas = nPruebas;

    resultados(metodo).pruebas = struct( ...
        'tiempo', num2cell(tiemposPruebas), ...
        'mejorValor', num2cell(mejoresPruebas), ...
        'mejorIndividuo', num2cell( ...
            mejoresIndividuos, 2));

    resultados(metodo).tiempoPromedio = tiempoPromedio;
    resultados(metodo).promedio = promedio;
    resultados(metodo).mejorValor = mejorGlobal;
    resultados(metodo).mejorIndividuo = individuoMejor;
    resultados(metodo).desviacionEstandar = desviacionEstandar;
    resultados(metodo).tiemposPruebas = tiemposPruebas;
    resultados(metodo).mejoresPruebas = mejoresPruebas;
    resultados(metodo).mejoresIndividuos = mejoresIndividuos;
    resultados(metodo).mejoresIteraciones = mejoresIteraciones;

end

end


% ==============================================================
% CRUCE BLX-ALPHA PARA INVENTARIO
% ==============================================================

function [hijo1, hijo2] = cruceBLXAlphaInventario( ...
    padre1, padre2, alpha, limiteInferior, limiteSuperior)

padre1 = padre1(:).';
padre2 = padre2(:).';

inferior = min(padre1, padre2);
superior = max(padre1, padre2);

distancia = superior - inferior;

limiteBLXInferior = inferior - alpha .* distancia;
limiteBLXSuperior = superior + alpha .* distancia;

hijo1 = limiteBLXInferior + ...
    rand(size(padre1)) .* ...
    (limiteBLXSuperior - limiteBLXInferior);

hijo2 = limiteBLXInferior + ...
    rand(size(padre2)) .* ...
    (limiteBLXSuperior - limiteBLXInferior);

% Aplicar límites específicos de cada variable
hijo1 = min(max(hijo1, limiteInferior), limiteSuperior);
hijo2 = min(max(hijo2, limiteInferior), limiteSuperior);

end


% ==============================================================
% REPARACIÓN DEL INDIVIDUO
% ==============================================================

function individuo = repararInventario(individuo)

% ==============================================================
% Restricción:
%
% sum(Qi/2 + Si) = 8000
%
% Se utiliza Q5 para completar la restricción.
% ==============================================================

I = 8000;

limiteQ5 = 100000;

% Límites de las variables
limiteS = [200 1200 2500 800 1500];

limiteQ = [12000 80000 150000 50000 100000];

% --------------------------------------------------------------
% Aplicar límites
% --------------------------------------------------------------

individuo(1:5) = min(max(individuo(1:5), 0), limiteQ);
individuo(6:10) = min(max(individuo(6:10), 0), limiteS);

% --------------------------------------------------------------
% Calcular inventario utilizado sin Q5
% --------------------------------------------------------------

inventarioSinQ5 = ...
    sum(individuo(1:4)/2) + ...
    sum(individuo(6:10));

% --------------------------------------------------------------
% Si se excede el inventario disponible, reducir las variables
% Q1-Q4 y S1-S5 proporcionalmente
% --------------------------------------------------------------

if inventarioSinQ5 >= I

    factor = (I * 0.999) / inventarioSinQ5;

    individuo(1:4) = individuo(1:4) * factor;
    individuo(6:10) = individuo(6:10) * factor;

    inventarioSinQ5 = ...
        sum(individuo(1:4)/2) + ...
        sum(individuo(6:10));

end

% --------------------------------------------------------------
% Calcular Q5 para cumplir exactamente la restricción
% --------------------------------------------------------------

individuo(5) = 2 * (I - inventarioSinQ5);

% --------------------------------------------------------------
% Verificar límite de Q5
% --------------------------------------------------------------

if individuo(5) <= 0
    individuo(5) = 0.000001;
end

if individuo(5) > limiteQ5
    individuo(5) = limiteQ5;
end

% --------------------------------------------------------------
% K no participa en la restricción, solamente se mantienen
% dentro de sus límites
% --------------------------------------------------------------

limiteK = [500 2000 5000 1500 3000];

individuo(11:15) = ...
    min(max(individuo(11:15), 0), limiteK);

end
%}

%{
function resultados = pruebaIteracionesInventario( ...
    nPoblacion, nIteraciones, nPruebas, alpha)

% ==============================================================
% PRUEBA DEL ALGORITMO GENÉTICO - OPTIMIZACIÓN DE INVENTARIO
%
% Selección:
%   Torneo
%
% Cruce:
%   BLX-alpha
%
% Objetivo:
%   Minimizar fitnessInventario
%
% El parámetro nIteraciones se modifica manualmente para evaluar:
%
%   10, 20, 30, 50, 100, 150, 200
%
% Ejemplo:
%   pruebaIteracionesInventario(48, 10, 5, 0.5)
%   pruebaIteracionesInventario(48, 20, 5, 0.5)
%   ...
%
% ==============================================================

% ==============================================================
% VALORES POR DEFECTO
% ==============================================================

if nargin < 1 || isempty(nPoblacion)
    nPoblacion = 48;
end

if nargin < 2 || isempty(nIteraciones)
    nIteraciones = 200;
end

if nargin < 3 || isempty(nPruebas)
    nPruebas = 5;
end

if nargin < 4 || isempty(alpha)
    alpha = 0.5;
end

% ==============================================================
% VALIDACIONES
% ==============================================================

validateattributes(nPoblacion, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(nIteraciones, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(nPruebas, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(alpha, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'nonnegative'});

if mod(nPoblacion, 4) ~= 0
    error('El tamaño de la población debe ser múltiplo de 4.');
end

% ==============================================================
% LIMITES DE LAS VARIABLES
%
% [Q1 Q2 Q3 Q4 Q5 S1 S2 S3 S4 S5 K1 K2 K3 K4 K5]
% ==============================================================

limiteInferior = [ ...
    0 0 0 0 0 ...
    0 0 0 0 0 ...
    0 0 0 0 0];

limiteSuperior = [ ...
    12000 80000 150000 50000 100000 ...
    200 1200 2500 800 1500 ...
    500 2000 5000 1500 3000];

% ==============================================================
% VARIABLES PARA GUARDAR RESULTADOS
% ==============================================================

tiemposPruebas = zeros(nPruebas, 1);
mejoresPruebas = zeros(nPruebas, 1);
mejoresIndividuos = zeros(nPruebas, 15);

% Guarda el mejor fitness de cada iteración
mejoresIteraciones = zeros(nIteraciones, nPruebas);

% ==============================================================
% ENCABEZADO
% ==============================================================

fprintf('\n');
fprintf('####################################################################\n');
fprintf('       PRUEBA DE ITERACIONES - INVENTARIO\n');
fprintf('####################################################################\n');

fprintf('\n=============================================\n');
fprintf('Selección: Torneo\n');
fprintf('Cruce: BLX-alpha\n');
fprintf('Alpha: %.2f\n', alpha);
fprintf('Población: %d\n', nPoblacion);
fprintf('Iteraciones: %d\n', nIteraciones);
fprintf('Número de pruebas: %d\n', nPruebas);
fprintf('=============================================\n');

% ==============================================================
% REALIZAR LAS PRUEBAS
% ==============================================================

for prueba = 1:nPruebas

    fprintf('\n=============================================\n');
    fprintf('PRUEBA %d DE %d\n', prueba, nPruebas);
    fprintf('Selección: Torneo\n');
    fprintf('Cruce: BLX-alpha\n');
    fprintf('Alpha: %.2f\n', alpha);
    fprintf('Iteraciones: %d\n', nIteraciones);
    fprintf('=============================================\n');

    % ----------------------------------------------------------
    % Generar población inicial
    % ----------------------------------------------------------

    poblacion = generarPoblacionInventario(nPoblacion);

    mejorValor = inf;
    mejorIndividuo = [];

    historialMejor = zeros(nIteraciones, 1);

    % ----------------------------------------------------------
    % Iniciar medición de tiempo
    % ----------------------------------------------------------

    tic;

    % ==========================================================
    % CICLO EVOLUTIVO
    % ==========================================================

    for iteracion = 1:nIteraciones

        % ------------------------------------------------------
        % Evaluar población
        % ------------------------------------------------------

        aptitud = zeros(nPoblacion, 1);

        for i = 1:nPoblacion

            aptitud(i) = fitnessInventario( ...
                poblacion(i,1:5), ...
                poblacion(i,6:10), ...
                poblacion(i,11:15));

        end

        % ------------------------------------------------------
        % Buscar mejor individuo de la iteración
        % ------------------------------------------------------

        [valorIteracion, indiceMejor] = min(aptitud);

        if valorIteracion < mejorValor

            mejorValor = valorIteracion;
            mejorIndividuo = poblacion(indiceMejor, :);

        end

        % Guardar histórico del mejor
        historialMejor(iteracion) = mejorValor;

        % ------------------------------------------------------
        % SELECCIÓN POR TORNEO
        %
        % Torneos de 4 individuos
        % 2 ganadores por torneo
        % ------------------------------------------------------

        [padres, ~] = seleccionTorneo( ...
            poblacion, ...
            aptitud, ...
            4, ...
            2, ...
            'min');

        % ------------------------------------------------------
        % CREAR HIJOS
        % ------------------------------------------------------

        hijos = zeros(nPoblacion/2, 15);

        contadorHijo = 1;

        for j = 1:2:size(padres,1)-1

            padre1 = padres(j,:);
            padre2 = padres(j+1,:);

            % --------------------------------------------------
            % Cruce BLX-alpha
            % --------------------------------------------------

            [hijo1, hijo2] = cruceBLXAlphaInventario( ...
                padre1, ...
                padre2, ...
                alpha, ...
                limiteInferior, ...
                limiteSuperior);

            % --------------------------------------------------
            % Reparar restricción de inventario
            % --------------------------------------------------

            hijo1 = repararInventario(hijo1);
            hijo2 = repararInventario(hijo2);

            hijos(contadorHijo,:) = hijo1;
            hijos(contadorHijo+1,:) = hijo2;

            contadorHijo = contadorHijo + 2;

        end

        % ------------------------------------------------------
        % Nueva población
        % ------------------------------------------------------

        poblacion = [padres; hijos];

    end

    % ==========================================================
    % FINALIZAR TIEMPO
    % ==========================================================

    tiempo = toc;

    % Guardar resultados
    tiemposPruebas(prueba) = tiempo;
    mejoresPruebas(prueba) = mejorValor;
    mejoresIndividuos(prueba,:) = mejorIndividuo;

    mejoresIteraciones(:,prueba) = historialMejor;

    % ==========================================================
    % RESULTADO DE LA PRUEBA
    % ==========================================================

    fprintf('\nResultado de la prueba %d:\n', prueba);

    fprintf('Tiempo de ejecución: %.6f segundos\n', ...
        tiempo);

    fprintf('Mejor valor f(X): %.6f\n', ...
        mejorValor);

    fprintf('Mejor individuo X:\n');

    fprintf('Q: ');
    fprintf('%.6f ', mejorIndividuo(1:5));
    fprintf('\n');

    fprintf('S: ');
    fprintf('%.6f ', mejorIndividuo(6:10));
    fprintf('\n');

    fprintf('K: ');
    fprintf('%.6f ', mejorIndividuo(11:15));
    fprintf('\n');

end

% ==============================================================
% TABLA DE RESULTADOS INDIVIDUALES
% ==============================================================

fprintf('\n\n====================================================================\n');
fprintf('       RESULTADOS INDIVIDUALES - TORNEO + BLX-alpha\n');
fprintf('====================================================================\n');

fprintf('%-8s %-18s %-18s\n', ...
    'Prueba', ...
    'Tiempo (s)', ...
    'Mejor f(X)');

fprintf('--------------------------------------------------------------------\n');

for prueba = 1:nPruebas

    fprintf('%-8d %-18.6f %-18.6f\n', ...
        prueba, ...
        tiemposPruebas(prueba), ...
        mejoresPruebas(prueba));

end

fprintf('====================================================================\n');

% ==============================================================
% MEJORES INDIVIDUOS DE CADA PRUEBA
% ==============================================================

fprintf('\n====================================================================\n');
fprintf('             MEJORES INDIVIDUOS EN CADA PRUEBA\n');
fprintf('====================================================================\n');

for prueba = 1:nPruebas

    fprintf('Prueba %d\n', prueba);

    fprintf('Mejor f(X): %.6f\n', ...
        mejoresPruebas(prueba));

    fprintf('Individuo X:\n');

    fprintf('Q: ');
    fprintf('%.6f ', mejoresIndividuos(prueba,1:5));
    fprintf('\n');

    fprintf('S: ');
    fprintf('%.6f ', mejoresIndividuos(prueba,6:10));
    fprintf('\n');

    fprintf('K: ');
    fprintf('%.6f ', mejoresIndividuos(prueba,11:15));
    fprintf('\n');

    fprintf('--------------------------------------------------------------------\n');

end

% ==============================================================
% RESUMEN ESTADÍSTICO
% ==============================================================

tiempoPromedio = mean(tiemposPruebas);

promedio = mean(mejoresPruebas);

% Desviación estándar de los mejores resultados
% obtenidos en las 5 pruebas
desviacionEstandar = std(mejoresPruebas);

% Mejor resultado global
[mejorGlobal, pruebaMejor] = min(mejoresPruebas);

individuoMejor = mejoresIndividuos(pruebaMejor,:);

% ==============================================================
% MOSTRAR RESUMEN
% ==============================================================

fprintf('\n====================================================================\n');
fprintf('                    RESUMEN ESTADÍSTICO\n');
fprintf('====================================================================\n');

fprintf('Tiempo promedio:          %.6f segundos\n', ...
    tiempoPromedio);

fprintf('Promedio mejor f(X):      %.6f\n', ...
    promedio);

fprintf('Desviación estándar:      %.6f\n', ...
    desviacionEstandar);

fprintf('Mejor f(X) global:        %.6f\n', ...
    mejorGlobal);

fprintf('Prueba del mejor resultado: %d\n', ...
    pruebaMejor);

fprintf('--------------------------------------------------------------------\n');

fprintf('Individuo X del mejor resultado:\n');

fprintf('Q: ');
fprintf('%.6f ', individuoMejor(1:5));
fprintf('\n');

fprintf('S: ');
fprintf('%.6f ', individuoMejor(6:10));
fprintf('\n');

fprintf('K: ');
fprintf('%.6f ', individuoMejor(11:15));
fprintf('\n');

fprintf('====================================================================\n');

% ==============================================================
% TABLA FINAL
% ==============================================================

fprintf('\n====================================================================\n');
fprintf('                         TABLA FINAL\n');
fprintf('====================================================================\n');

fprintf('Selección:                Torneo\n');
fprintf('Cruce:                    BLX-alpha\n');
fprintf('Alpha:                    %.2f\n', alpha);
fprintf('Población:                %d\n', nPoblacion);
fprintf('Iteraciones:              %d\n', nIteraciones);
fprintf('Número de pruebas:        %d\n', nPruebas);

fprintf('\nMejor valor f(X):         %.6f\n', ...
    mejorGlobal);

fprintf('Desviación estándar:      %.6f\n', ...
    desviacionEstandar);

fprintf('Tiempo promedio:          %.6f s\n', ...
    tiempoPromedio);

fprintf('====================================================================\n');

% ==============================================================
% GUARDAR RESULTADOS
% ==============================================================

resultados.seleccion = 'Torneo';
resultados.cruce = 'BLX-alpha';
resultados.alpha = alpha;

resultados.nPoblacion = nPoblacion;
resultados.nIteraciones = nIteraciones;
resultados.nPruebas = nPruebas;

resultados.pruebas = struct( ...
    'tiempo', num2cell(tiemposPruebas), ...
    'mejorValor', num2cell(mejoresPruebas), ...
    'mejorIndividuo', num2cell( ...
        mejoresIndividuos, 2));

resultados.tiempoPromedio = tiempoPromedio;

resultados.promedio = promedio;

resultados.mejorValor = mejorGlobal;

resultados.mejorIndividuo = individuoMejor;

resultados.desviacionEstandar = desviacionEstandar;

resultados.tiemposPruebas = tiemposPruebas;

resultados.mejoresPruebas = mejoresPruebas;

resultados.mejoresIndividuos = mejoresIndividuos;

resultados.mejoresIteraciones = mejoresIteraciones;

end
%}

function resultados = pruebaAlgoritmoGeneticoInventarioMutacion( ...
    nPoblacion, nIteraciones, nPruebas, alpha, probMutacion)

% ==============================================================
% PRUEBA DEL ALGORITMO GENÉTICO - OPTIMIZACIÓN DE INVENTARIO
%
% Selección:
%   Torneo
%
% Cruce:
%   BLX-alpha
%
% Mutación:
%   Mutación para inventario mediante perturbación normal
%
% Configuración:
%   Población: 48
%   Iteraciones: 200
%   Pruebas: 5
%   Alpha: 0.5
%
% Objetivo:
%   Minimizar fitnessInventario
%
% ==============================================================
%
% El individuo tiene la forma:
%
% [Q1 Q2 Q3 Q4 Q5 S1 S2 S3 S4 S5 K1 K2 K3 K4 K5]
%
% ==============================================================
%
% RESULTADOS REPORTADOS:
%
%   - Mejor f(X) de cada prueba
%   - Individuo correspondiente a cada mejor resultado
%   - Promedio de los mejores resultados
%   - Desviación estándar
%   - Mejor resultado global
%   - Individuo correspondiente al mejor resultado global
%   - Tiempo promedio
%
% ==============================================================


% ==============================================================
% VALORES POR DEFECTO
% ==============================================================

if nargin < 1 || isempty(nPoblacion)
    nPoblacion = 48;
end

if nargin < 2 || isempty(nIteraciones)
    nIteraciones = 200;
end

if nargin < 3 || isempty(nPruebas)
    nPruebas = 5;
end

if nargin < 4 || isempty(alpha)
    alpha = 0.5;
end

if nargin < 5 || isempty(probMutacion)
    probMutacion = 0.50;
end


% ==============================================================
% VALIDACIONES
% ==============================================================

validateattributes(nPoblacion, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(nIteraciones, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(nPruebas, {'numeric'}, ...
    {'scalar', 'integer', 'positive'});

validateattributes(alpha, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'nonnegative'});

validateattributes(probMutacion, {'numeric'}, ...
    {'scalar', 'real', 'finite', '>=', 0, '<=', 1});


if mod(nPoblacion, 4) ~= 0
    error('El tamaño de la población debe ser múltiplo de 4.');
end


% ==============================================================
% LIMITES DE LAS VARIABLES
%
% [Q1 Q2 Q3 Q4 Q5 S1 S2 S3 S4 S5 K1 K2 K3 K4 K5]
% ==============================================================

limiteInferior = [ ...
    0 0 0 0 0 ...
    0 0 0 0 0 ...
    0 0 0 0 0];

limiteSuperior = [ ...
    12000 80000 150000 50000 100000 ...
    200 1200 2500 800 1500 ...
    500 2000 5000 1500 3000];


% ==============================================================
% VARIABLES PARA GUARDAR RESULTADOS
% ==============================================================

tiemposPruebas = zeros(nPruebas, 1);

mejoresPruebas = zeros(nPruebas, 1);

mejoresIndividuos = zeros(nPruebas, 15);

% Histórico del mejor fitness de cada iteración
mejoresIteraciones = ...
    zeros(nIteraciones, nPruebas);


% ==============================================================
% ENCABEZADO
% ==============================================================

fprintf('\n');
fprintf('####################################################################\n');
fprintf('        ALGORITMO GENÉTICO - INVENTARIO + MUTACIÓN\n');
fprintf('####################################################################\n');

fprintf('\n');
fprintf('Selección:                Torneo\n');
fprintf('Cruce:                    BLX-alpha\n');
fprintf('Alpha:                    %.2f\n', alpha);
fprintf('Mutación:                 Inventario\n');
fprintf('Probabilidad mutación:    %.2f\n', probMutacion);
fprintf('Población:                %d\n', nPoblacion);
fprintf('Iteraciones:              %d\n', nIteraciones);
fprintf('Número de pruebas:        %d\n', nPruebas);

fprintf('####################################################################\n');


% ==============================================================
% REALIZAR LAS PRUEBAS
% ==============================================================

for prueba = 1:nPruebas

    fprintf('\n');
    fprintf('=============================================\n');
    fprintf('PRUEBA %d DE %d\n', prueba, nPruebas);
    fprintf('=============================================\n');

    % ----------------------------------------------------------
    % Generar población inicial
    % ----------------------------------------------------------

    poblacion = generarPoblacionInventario(nPoblacion);

    % ----------------------------------------------------------
    % Variables para almacenar el mejor resultado
    % ----------------------------------------------------------

    mejorValor = inf;

    mejorIndividuo = [];

    historialMejor = ...
        zeros(nIteraciones, 1);


    % ----------------------------------------------------------
    % Iniciar medición del tiempo
    % ----------------------------------------------------------

    tic;


    % ==========================================================
    % CICLO EVOLUTIVO
    % ==========================================================

    for iteracion = 1:nIteraciones

        % ------------------------------------------------------
        % EVALUAR POBLACIÓN
        % ------------------------------------------------------

        aptitud = zeros(nPoblacion, 1);

        for i = 1:nPoblacion

            aptitud(i) = fitnessInventario( ...
                poblacion(i,1:5), ...
                poblacion(i,6:10), ...
                poblacion(i,11:15));

        end


        % ------------------------------------------------------
        % OBTENER MEJOR INDIVIDUO
        % ------------------------------------------------------

        [valorIteracion, indiceMejor] = ...
            min(aptitud);

        if valorIteracion < mejorValor

            mejorValor = valorIteracion;

            mejorIndividuo = ...
                poblacion(indiceMejor,:);

        end

        % Guardar mejor resultado acumulado
        historialMejor(iteracion) = ...
            mejorValor;


        % ======================================================
        % SELECCIÓN POR TORNEO
        %
        % Torneos de 4 individuos
        % 2 ganadores por torneo
        %
        % 48 individuos:
        %
        % 48 / 4 = 12 torneos
        %
        % 12 * 2 = 24 padres
        % ======================================================

        [padres, ~] = seleccionTorneo( ...
            poblacion, ...
            aptitud, ...
            4, ...
            2, ...
            'min');


        % ======================================================
        % CREAR HIJOS
        % ======================================================

        hijos = zeros(nPoblacion/2, 15);

        contadorHijo = 1;


        for j = 1:2:size(padres,1)-1

            padre1 = padres(j,:);
            padre2 = padres(j+1,:);


            % --------------------------------------------------
            % CRUCE BLX-ALPHA
            % --------------------------------------------------

            [hijo1, hijo2] = ...
                cruceBLXAlphaInventario( ...
                padre1, ...
                padre2, ...
                alpha, ...
                limiteInferior, ...
                limiteSuperior);


            % --------------------------------------------------
            % REPARAR HIJOS
            % --------------------------------------------------

            hijo1 = repararInventario(hijo1);

            hijo2 = repararInventario(hijo2);


            % --------------------------------------------------
            % MUTACIÓN
            %
            % La mutación solamente se aplica si el número
            % aleatorio es menor o igual a la probabilidad
            % definida.
            % --------------------------------------------------

            if rand < probMutacion

                hijo1 = mutacionInventario( ...
                    hijo1, 0.10);

            end


            if rand < probMutacion

                hijo2 = mutacionInventario( ...
                    hijo2, 0.10);

            end


            % --------------------------------------------------
            % REPARAR NUEVAMENTE DESPUÉS DE MUTAR
            % --------------------------------------------------
            %
            % La función mutacionInventario ya recalcula Q5,
            % pero se realiza una reparación adicional para
            % garantizar que el individuo conserve todos sus
            % límites.
            % --------------------------------------------------

            hijo1 = repararInventario(hijo1);

            hijo2 = repararInventario(hijo2);


            % --------------------------------------------------
            % GUARDAR HIJOS
            % --------------------------------------------------

            hijos(contadorHijo,:) = hijo1;

            hijos(contadorHijo+1,:) = hijo2;

            contadorHijo = contadorHijo + 2;

        end


        % ======================================================
        % NUEVA POBLACIÓN
        % ======================================================

        poblacion = [padres; hijos];

    end


    % ==========================================================
    % FINALIZAR MEDICIÓN DEL TIEMPO
    % ==========================================================

    tiempo = toc;


    % ==========================================================
    % GUARDAR RESULTADOS DE LA PRUEBA
    % ==========================================================

    tiemposPruebas(prueba) = ...
        tiempo;

    mejoresPruebas(prueba) = ...
        mejorValor;

    mejoresIndividuos(prueba,:) = ...
        mejorIndividuo;

    mejoresIteraciones(:,prueba) = ...
        historialMejor;


    % ==========================================================
    % MOSTRAR RESULTADO DE LA PRUEBA
    % ==========================================================

    fprintf('\nResultado de la prueba %d:\n', prueba);

    fprintf('Tiempo de ejecución: %.6f segundos\n', ...
        tiempo);

    fprintf('Mejor valor f(X): %.10f\n', ...
        mejorValor);

    fprintf('Mejor individuo X:\n');

    fprintf('Q: ');
    fprintf('%.6f ', mejorIndividuo(1:5));
    fprintf('\n');

    fprintf('S: ');
    fprintf('%.6f ', mejorIndividuo(6:10));
    fprintf('\n');

    fprintf('K: ');
    fprintf('%.6f ', mejorIndividuo(11:15));
    fprintf('\n');

end


% ==============================================================
% TABLA DE RESULTADOS INDIVIDUALES
% ==============================================================

fprintf('\n\n');
fprintf('====================================================================\n');
fprintf('       RESULTADOS INDIVIDUALES - TORNEO + BLX-alpha + MUTACIÓN\n');
fprintf('====================================================================\n');

fprintf('%-8s %-18s %-20s\n', ...
    'Prueba', ...
    'Tiempo (s)', ...
    'Mejor f(X)');

fprintf('--------------------------------------------------------------------\n');


for prueba = 1:nPruebas

    fprintf('%-8d %-18.6f %-20.10f\n', ...
        prueba, ...
        tiemposPruebas(prueba), ...
        mejoresPruebas(prueba));

end

fprintf('====================================================================\n');


% ==============================================================
% TABLA DE MEJORES INDIVIDUOS
% ==============================================================

fprintf('\n');
fprintf('====================================================================\n');
fprintf('             MEJORES INDIVIDUOS EN CADA PRUEBA\n');
fprintf('====================================================================\n');


for prueba = 1:nPruebas

    fprintf('\nPrueba %d\n', prueba);

    fprintf('Mejor f(X): %.10f\n', ...
        mejoresPruebas(prueba));

    fprintf('X = [');
    fprintf(' %.6f', ...
        mejoresIndividuos(prueba,:));
    fprintf(' ]\n');

    fprintf('Q: ');
    fprintf('%.6f ', ...
        mejoresIndividuos(prueba,1:5));
    fprintf('\n');

    fprintf('S: ');
    fprintf('%.6f ', ...
        mejoresIndividuos(prueba,6:10));
    fprintf('\n');

    fprintf('K: ');
    fprintf('%.6f ', ...
        mejoresIndividuos(prueba,11:15));
    fprintf('\n');

    fprintf('--------------------------------------------------------------------\n');

end


% ==============================================================
% RESUMEN ESTADÍSTICO
% ==============================================================

tiempoPromedio = ...
    mean(tiemposPruebas);

promedio = ...
    mean(mejoresPruebas);

% Desviación estándar de los mejores resultados
% obtenidos en las pruebas
desviacionEstandar = ...
    std(mejoresPruebas);


% ==============================================================
% MEJOR RESULTADO GLOBAL
% ==============================================================

[mejorGlobal, pruebaMejor] = ...
    min(mejoresPruebas);

individuoMejor = ...
    mejoresIndividuos(pruebaMejor,:);


% ==============================================================
% MOSTRAR RESUMEN ESTADÍSTICO
% ==============================================================

fprintf('\n');
fprintf('====================================================================\n');
fprintf('                    RESUMEN ESTADÍSTICO\n');
fprintf('====================================================================\n');

fprintf('Selección:                Torneo\n');
fprintf('Cruce:                    BLX-alpha\n');
fprintf('Alpha:                    %.2f\n', alpha);
fprintf('Mutación:                 Inventario\n');
fprintf('Probabilidad mutación:    %.2f\n', probMutacion);
fprintf('Población:                %d\n', nPoblacion);
fprintf('Iteraciones:              %d\n', nIteraciones);
fprintf('Número de pruebas:        %d\n', nPruebas);

fprintf('\n');

fprintf('Tiempo promedio:          %.6f segundos\n', ...
    tiempoPromedio);

fprintf('Promedio mejor f(X):      %.10f\n', ...
    promedio);

fprintf('Desviación estándar:      %.10f\n', ...
    desviacionEstandar);

fprintf('Mejor f(X) global:         %.10f\n', ...
    mejorGlobal);

fprintf('Prueba del mejor resultado: %d\n', ...
    pruebaMejor);

fprintf('--------------------------------------------------------------------\n');

fprintf('Individuo X del mejor resultado global:\n');

fprintf('X = [');
fprintf(' %.6f', individuoMejor);
fprintf(' ]\n');

fprintf('Q: ');
fprintf('%.6f ', individuoMejor(1:5));
fprintf('\n');

fprintf('S: ');
fprintf('%.6f ', individuoMejor(6:10));
fprintf('\n');

fprintf('K: ');
fprintf('%.6f ', individuoMejor(11:15));
fprintf('\n');

fprintf('====================================================================\n');


% ==============================================================
% TABLA FINAL
% ==============================================================

fprintf('\n');
fprintf('====================================================================\n');
fprintf('                         TABLA FINAL\n');
fprintf('====================================================================\n');

fprintf('%-30s %s\n', ...
    'Configuración', 'Valor');

fprintf('--------------------------------------------------------------------\n');

fprintf('%-30s %s\n', ...
    'Selección', 'Torneo');

fprintf('%-30s %s\n', ...
    'Cruce', 'BLX-alpha');

fprintf('%-30s %.2f\n', ...
    'Alpha', alpha);

fprintf('%-30s %d\n', ...
    'Población', nPoblacion);

fprintf('%-30s %d\n', ...
    'Iteraciones', nIteraciones);

fprintf('%-30s %d\n', ...
    'Número de pruebas', nPruebas);

fprintf('%-30s %.2f\n', ...
    'Probabilidad de mutación', probMutacion);

fprintf('--------------------------------------------------------------------\n');

fprintf('%-30s %.10f\n', ...
    'Mejor f(X)', mejorGlobal);

fprintf('%-30s %.10f\n', ...
    'Desviación estándar', desviacionEstandar);

fprintf('%-30s %.6f s\n', ...
    'Tiempo promedio', tiempoPromedio);

fprintf('====================================================================\n');


% ==============================================================
% GUARDAR RESULTADOS
% ==============================================================

resultados.seleccion = ...
    'Torneo';

resultados.cruce = ...
    'BLX-alpha';

resultados.mutacion = ...
    'MutacionInventario';

resultados.probMutacion = ...
    probMutacion;

resultados.desviacionRelativa = ...
    0.10;

resultados.alpha = ...
    alpha;

resultados.nPoblacion = ...
    nPoblacion;

resultados.nIteraciones = ...
    nIteraciones;

resultados.nPruebas = ...
    nPruebas;


resultados.pruebas = ...
    struct( ...
    'tiempo', num2cell(tiemposPruebas), ...
    'mejorValor', num2cell(mejoresPruebas), ...
    'mejorIndividuo', ...
    num2cell(mejoresIndividuos, 2));


resultados.tiempoPromedio = ...
    tiempoPromedio;

resultados.promedio = ...
    promedio;

resultados.mejorValor = ...
    mejorGlobal;

resultados.mejorIndividuo = ...
    individuoMejor;

resultados.desviacionEstandar = ...
    desviacionEstandar;

resultados.tiemposPruebas = ...
    tiemposPruebas;

resultados.mejoresPruebas = ...
    mejoresPruebas;

resultados.mejoresIndividuos = ...
    mejoresIndividuos;

resultados.mejoresIteraciones = ...
    mejoresIteraciones;

end

% ==============================================================
% CRUCE BLX-ALPHA PARA INVENTARIO
% ==============================================================

function [hijo1, hijo2] = cruceBLXAlphaInventario( ...
    padre1, padre2, alpha, limiteInferior, limiteSuperior)

padre1 = padre1(:).';
padre2 = padre2(:).';

inferior = min(padre1, padre2);

superior = max(padre1, padre2);

distancia = superior - inferior;

limiteBLXInferior = ...
    inferior - alpha .* distancia;

limiteBLXSuperior = ...
    superior + alpha .* distancia;

hijo1 = limiteBLXInferior + ...
    rand(size(padre1)) .* ...
    (limiteBLXSuperior - limiteBLXInferior);

hijo2 = limiteBLXInferior + ...
    rand(size(padre2)) .* ...
    (limiteBLXSuperior - limiteBLXInferior);

% Aplicar límites específicos
hijo1 = min(max(hijo1, limiteInferior), limiteSuperior);

hijo2 = min(max(hijo2, limiteInferior), limiteSuperior);

end


% ==============================================================
% REPARACIÓN DEL INDIVIDUO
% ==============================================================

function individuo = repararInventario(individuo)

I = 8000;

limiteQ = [12000 80000 150000 50000 100000];

limiteS = [200 1200 2500 800 1500];

limiteK = [500 2000 5000 1500 3000];

% --------------------------------------------------------------
% Aplicar límites
% --------------------------------------------------------------

individuo(1:5) = ...
    min(max(individuo(1:5), 0), limiteQ);

individuo(6:10) = ...
    min(max(individuo(6:10), 0), limiteS);

individuo(11:15) = ...
    min(max(individuo(11:15), 0), limiteK);

% --------------------------------------------------------------
% Inventario utilizado sin Q5
% --------------------------------------------------------------

inventarioSinQ5 = ...
    sum(individuo(1:4)/2) + ...
    sum(individuo(6:10));

% --------------------------------------------------------------
% Evitar que Q5 resulte negativo
% --------------------------------------------------------------

if inventarioSinQ5 >= I

    factor = (I * 0.999) / inventarioSinQ5;

    individuo(1:4) = ...
        individuo(1:4) * factor;

    individuo(6:10) = ...
        individuo(6:10) * factor;

    inventarioSinQ5 = ...
        sum(individuo(1:4)/2) + ...
        sum(individuo(6:10));

end

% --------------------------------------------------------------
% Calcular Q5
% --------------------------------------------------------------

individuo(5) = ...
    2 * (I - inventarioSinQ5);

% --------------------------------------------------------------
% Verificar Q5
% --------------------------------------------------------------

if individuo(5) <= 0
    individuo(5) = 0.000001;
end

if individuo(5) > limiteQ(5)
    individuo(5) = limiteQ(5);
end

end


function Z = fitnessInventario(Q, S, K)

    % ==========================================================
    % FUNCION OBJETIVO DEL PROBLEMA DE OPTIMIZACION DE INVENTARIO
    % ==========================================================

    D = [12000 80000 150000 50000 100000];
    m = [20 220 900 120 180];
    mu = [300 4000 7000 2000 3500];
    sigma = [100 1200 2500 700 1100];
    I=8000;

    % Limites de S
    limiteS = [200 1200 2500 800 1500];

    % Limites de K
    limiteK = [500 2000 5000 1500 3000];

    % Verificar cantidad de variables
    if length(Q) ~= 5 || length(S) ~= 5 || length(K) ~= 5
        error('Q, S y K deben contener exactamente 5 valores.');
    end

    % Verificar Q > 0
    if any(Q <= 0)
        Z = 1e12;
        return;
    end

    % Verificar limites de S
    if any(S < 0) || any(S > limiteS)
        Z = 1e12;
        return;
    end

    % Verificar limites de K
    if any(K < 0) || any(K > limiteK)
        Z = 1e12;
        return;
    end

    % Numero de subintervalos
    n = 300;

    % Inicializar funcion objetivo
    Z = 0;

    for i = 1:5

        % Limite inferior de la integral
        a = S(i) + K(i);

        % Aproximacion del infinito
        b = max(mu(i) + 8*sigma(i), ...
                a + 8*sigma(i));

        % Integrando de la Ecuacion 8
        f = @(x) ((x - S(i) - K(i)) ./ ...
            (m(i) * sqrt(2*pi) * sigma(i))) .* ...
            exp(-0.5 * ((x - mu(i)) ./ sigma(i)).^2);

        % Integral mediante Simpson 3/8
        integral_i = simpson38(f, a, b, n);

        % Termino del item i
        Z = Z + (D(i) / Q(i)) * integral_i;

    end

    % ==========================================================
    % RESTRICCION DE LA ECUACION 9
    % ==========================================================

    inventario = sum(Q/2 + S);

    errorRestriccion = inventario - I;

    % Penalizacion
    lambda = 1e6;

    Z = Z + lambda * errorRestriccion^2;

end


% ==============================================================
% FUNCION SIMPSON 3/8 COMPUESTA
% ==============================================================

function resultado = simpson38(f, a, b, n)

    % n debe ser multiplo de 3
    if mod(n,3) ~= 0
        error('El numero de subintervalos n debe ser multiplo de 3.');
    end

    h = (b-a)/n;

    x = a:h:b;

    y = f(x);

    % Extremos
    resultado = y(1) + y(end);

    % Coeficientes de Simpson 3/8
    for j = 2:n

        if mod(j-1,3) == 0
            resultado = resultado + 2*y(j);
        else
            resultado = resultado + 3*y(j);
        end

    end

    resultado = (3*h/8)*resultado;

end

function poblacion = generarPoblacionInventario(n)

    % ==========================================================
    % GENERACION DE POBLACION INICIAL - INVENTARIO
    %
    % Cada individuo tiene 15 variables:
    %
    % [Q1 Q2 Q3 Q4 Q5 S1 S2 S3 S4 S5 K1 K2 K3 K4 K5]
    %
    % Se generan 14 variables aleatoriamente y Q5 se calcula
    % utilizando la restriccion:
    %
    % sum(Qi/2 + Si) = I
    %
    % ==========================================================

    % Presupuesto total de inventario
    I = 8000;

    % Limites superiores de Qi = Di
    limiteQ = [12000 80000 150000 50000 100000];

    % Limites superiores de Si
    limiteS = [200 1200 2500 800 1500];

    % Limites superiores de Ki
    limiteK = [500 2000 5000 1500 3000];

    % Inicializar poblacion
    poblacion = zeros(n, 15);

    % ==========================================================
    % Generar cada individuo
    % ==========================================================

    for individuo = 1:n

        valido = false;

        while ~valido

            % --------------------------------------------------
            % Generar Q1-Q4
            % --------------------------------------------------

            Q1 = rand * limiteQ(1);
            Q2 = rand * limiteQ(2);
            Q3 = rand * limiteQ(3);
            Q4 = rand * limiteQ(4);

            % --------------------------------------------------
            % Generar S1-S5
            % --------------------------------------------------

            S1 = rand * limiteS(1);
            S2 = rand * limiteS(2);
            S3 = rand * limiteS(3);
            S4 = rand * limiteS(4);
            S5 = rand * limiteS(5);

            % --------------------------------------------------
            % Calcular Q5 mediante la restriccion
            % --------------------------------------------------

            Q5 = 2 * (I ...
                - Q1/2 - S1 ...
                - Q2/2 - S2 ...
                - Q3/2 - S3 ...
                - Q4/2 - S4 ...
                - S5);

            % --------------------------------------------------
            % Generar K1-K5
            % --------------------------------------------------

            K1 = rand * limiteK(1);
            K2 = rand * limiteK(2);
            K3 = rand * limiteK(3);
            K4 = rand * limiteK(4);
            K5 = rand * limiteK(5);

            % --------------------------------------------------
            % Verificar que Q5 sea valido
            % --------------------------------------------------

            valido = Q5 > 0 && Q5 <= limiteQ(5);

        end

        % ------------------------------------------------------
        % Guardar individuo
        % ------------------------------------------------------

        poblacion(individuo, :) = [ ...
            Q1 Q2 Q3 Q4 Q5 ...
            S1 S2 S3 S4 S5 ...
            K1 K2 K3 K4 K5];

    end

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

function [individuoMutado, indice] = mutacionInventario( ...
    individuo, desviacionRelativa)

% ==============================================================
% MUTACIÓN PARA EL PROBLEMA DE INVENTARIO
%
% Individuo:
%
% [Q1 Q2 Q3 Q4 Q5 S1 S2 S3 S4 S5 K1 K2 K3 K4 K5]
%
% Se selecciona aleatoriamente una de las 14 variables
% independientes:
%
% Q1-Q4, S1-S5, K1-K5
%
% Q5 se calcula posteriormente para conservar:
%
% sum(Qi/2 + Si) = I
%
% La perturbación se genera mediante una distribución normal
% y su magnitud depende del rango de la variable seleccionada.
% ==============================================================

% ==============================================================
% VALORES POR DEFECTO
% ==============================================================

if nargin < 2 || isempty(desviacionRelativa)
    desviacionRelativa = 0.10;
end

% ==============================================================
% VALIDACIONES
% ==============================================================

validateattributes(individuo, {'numeric'}, ...
    {'vector', 'numel', 15, 'real', 'finite'});

validateattributes(desviacionRelativa, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'nonnegative'});

% Convertir a vector fila
individuo = individuo(:).';

% ==============================================================
% LIMITES
% ==============================================================

limiteQ = [ ...
    12000 80000 150000 50000 100000];

limiteS = [ ...
    200 1200 2500 800 1500];

limiteK = [ ...
    500 2000 5000 1500 3000];

% Variable dependiente
I = 8000;

% ==============================================================
% INDICES DE LAS 14 VARIABLES INDEPENDIENTES
%
% 1-4   -> Q1-Q4
% 6-10  -> S1-S5
% 11-15 -> K1-K5
% ==============================================================

indicesIndependientes = [ ...
    1:4, ...
    6:10, ...
    11:15];

% ==============================================================
% INTENTAR UNA MUTACIÓN VÁLIDA
% ==============================================================

maxIntentos = 1000;

for intento = 1:maxIntentos

    % ----------------------------------------------------------
    % Seleccionar aleatoriamente una variable independiente
    % ----------------------------------------------------------

    posicion = randi(numel(indicesIndependientes));

    indice = indicesIndependientes(posicion);

    % ----------------------------------------------------------
    % Determinar límites de la variable seleccionada
    % ----------------------------------------------------------

    if indice >= 1 && indice <= 4

        % Q1-Q4
        limiteInferior = 0;
        limiteSuperior = limiteQ(indice);

    elseif indice >= 6 && indice <= 10

        % S1-S5
        indiceS = indice - 5;

        limiteInferior = 0;
        limiteSuperior = limiteS(indiceS);

    else

        % K1-K5
        indiceK = indice - 10;

        limiteInferior = 0;
        limiteSuperior = limiteK(indiceK);

    end

    % ----------------------------------------------------------
    % Calcular desviación según el rango de la variable
    % ----------------------------------------------------------

    rango = limiteSuperior - limiteInferior;

    desviacion = desviacionRelativa * rango;

    % ----------------------------------------------------------
    % Crear individuo candidato
    % ----------------------------------------------------------

    candidato = individuo;

    % Mutación mediante distribución normal
    candidato(indice) = ...
        candidato(indice) + desviacion * randn;

    % ----------------------------------------------------------
    % Mantener la variable dentro de sus límites
    % ----------------------------------------------------------

    candidato(indice) = ...
        min(max(candidato(indice), limiteInferior), ...
        limiteSuperior);

    % ----------------------------------------------------------
    % Recalcular Q5 para conservar la restricción
    %
    % sum(Qi/2 + Si) = I
    %
    % Q5/2 = I - sum(Q1:Q4)/2 - sum(S1:S5)
    %
    % Q5 = 2 * (...)
    % ----------------------------------------------------------

    inventarioSinQ5 = ...
        sum(candidato(1:4) / 2) + ...
        sum(candidato(6:10));

    candidato(5) = ...
        2 * (I - inventarioSinQ5);

    % ----------------------------------------------------------
    % Verificar que Q5 permanezca dentro de sus límites
    % ----------------------------------------------------------

    if candidato(5) > 0 && ...
            candidato(5) <= limiteQ(5)

        individuoMutado = candidato;

        return;

    end

end

% ==============================================================
% Si no se encontró una mutación válida
% ==============================================================

error(['No fue posible generar una mutación válida después ', ...
       'de %d intentos.'], maxIntentos);

end