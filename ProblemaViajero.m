%{
function resultados = pruebaAlgoritmoGeneticoViajero( ...
        nPoblacion, nIteraciones, nPruebas)

    % ============================================================
    % PRUEBA DEL ALGORITMO GENÉTICO - PROBLEMA DEL VIAJERO
    %
    % Etapas:
    %   1. Generación de población
    %   2. Evaluación
    %   3. Selección
    %   4. Apareamiento mediante OX
    %   5. Evaluación de hijos
    %
    % No se aplica mutación.
    %
    % Se realizan varias pruebas independientes por cada método
    % de selección.
    % ============================================================

    if nargin < 1 || isempty(nPoblacion)
        nPoblacion = 48;
    end

    if nargin < 2 || isempty(nIteraciones)
        nIteraciones = 100;
    end

    if nargin < 3 || isempty(nPruebas)
        nPruebas = 5;
    end

    validateattributes(nPoblacion, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    validateattributes(nIteraciones, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    validateattributes(nPruebas, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    % Para facilitar el apareamiento padre-padre
    if mod(nPoblacion, 2) ~= 0
        error('nPoblacion debe ser un número par.');
    end

    % ============================================================
    % CONFIGURACIÓN
    % ============================================================

    nombresSeleccion = {'Elitismo', 'Torneo', 'Ruleta'};

    nMetodos = numel(nombresSeleccion);

    % Para la selección sobrevivirá la mitad de la población
    nIndividuos = nPoblacion / 2;

    % Resultados
    resultados = struct();

    % ============================================================
    % EJECUCIÓN DE CADA MÉTODO DE SELECCIÓN
    % ============================================================

    for metodo = 1:nMetodos

        nombre = nombresSeleccion{metodo};

        fprintf('\n=============================================\n');
        fprintf('MÉTODO DE SELECCIÓN: %s\n', nombre);
        fprintf('=============================================\n');

        % --------------------------------------------------------
        % DATOS DE TODAS LAS PRUEBAS DEL MÉTODO
        % --------------------------------------------------------

        tiemposPruebas = zeros(nPruebas, 1);
        mejoresPruebas = zeros(nPruebas, 1);
        mejoresIndividuos = zeros(nPruebas, 13);

        % Se conservan también los mejores resultados por iteración
        % de cada prueba
        mejoresIteraciones = zeros(nIteraciones, nPruebas);

        % ========================================================
        % REPETICIÓN DE PRUEBAS INDEPENDIENTES
        % ========================================================

        for prueba = 1:nPruebas

            fprintf('\n---------------------------------------------\n');
            fprintf('Método: %s | Prueba: %d de %d\n', ...
                nombre, prueba, nPruebas);
            fprintf('---------------------------------------------\n');

            tic;

            mejorGlobal = Inf;
            mejorIndividuo = [];

            % ----------------------------------------------------
            % POBLACIÓN INICIAL
            % ----------------------------------------------------

            poblacion = generarPoblacionInicial(nPoblacion);

            % ----------------------------------------------------
            % ITERACIONES
            % ----------------------------------------------------

            for iteracion = 1:nIteraciones

                % ====================================================
                % 1. EVALUACIÓN DE LA POBLACIÓN
                % ====================================================

                aptitud = arrayfun(@(i) ...
                    ProblemaViajeroFcn(poblacion(i, :)), ...
                    (1:nPoblacion).');

                % ====================================================
                % 2. SELECCIÓN
                % ====================================================

                switch metodo

                    case 1
                        % -------------------------------
                        % ELITISMO
                        % -------------------------------

                        [padres, ~] = seleccionElitismo( ...
                            poblacion, ...
                            aptitud, ...
                            nIndividuos);

                    case 2
                        % -------------------------------
                        % TORNEO
                        % -------------------------------

                        [padres, ~] = seleccionTorneo( ...
                            poblacion, ...
                            aptitud, ...
                            4, ...
                            2, ...
                            'min');

                    case 3
                        % -------------------------------
                        % RULETA
                        % -------------------------------

                        [padres, ~, ~] = seleccionRuleta( ...
                            poblacion, ...
                            aptitud, ...
                            nIndividuos);

                end

                % ====================================================
                % 3. APAREAMIENTO MEDIANTE OX
                % ====================================================

                nPadres = size(padres, 1);
                hijos = zeros(nPadres, 13);

                for i = 1:2:nPadres

                    padre1 = padres(i, :);
                    padre2 = padres(i + 1, :);

                    [hijo1, hijo2] = cruceOX(padre1, padre2);

                    hijos(i, :) = hijo1;
                    hijos(i + 1, :) = hijo2;

                end

                % ====================================================
                % 4. FORMACIÓN DE LA NUEVA GENERACIÓN
                % ====================================================

                poblacionNueva = [padres; hijos];

                % ====================================================
                % VERIFICACIÓN DEL TAMAÑO DE LA POBLACIÓN
                % ====================================================

                if size(poblacionNueva, 1) ~= nPoblacion
                    error(['El método %s produjo una población de ', ...
                        '%d individuos. Se esperaban %d.'], ...
                        nombre, size(poblacionNueva, 1), nPoblacion);
                end

                % ====================================================
                % 5. EVALUACIÓN DE LA NUEVA GENERACIÓN
                % ====================================================

                aptitudNueva = arrayfun(@(i) ...
                    ProblemaViajeroFcn(poblacionNueva(i, :)), ...
                    (1:nPoblacion).');

                % ====================================================
                % 6. MEJOR RESULTADO DE LA ITERACIÓN
                % ====================================================

                [mejorIteracion, indiceMejor] = min(aptitudNueva);

                mejoresIteraciones(iteracion, prueba) = ...
                    mejorIteracion;

                % Actualizar mejor solución global de esta prueba
                if mejorIteracion < mejorGlobal

                    mejorGlobal = mejorIteracion;

                    mejorIndividuo = ...
                        poblacionNueva(indiceMejor, :);

                end

                % La población para la siguiente iteración
                % está formada por los padres seleccionados y los hijos.
                poblacion = poblacionNueva;

            end

            % ========================================================
            % FINALIZACIÓN DE LA PRUEBA
            % ========================================================

            tiempoEjecucion = toc;

            % Guardar los datos de ESTA prueba
            tiemposPruebas(prueba) = tiempoEjecucion;

            mejoresPruebas(prueba) = mejorGlobal;

            mejoresIndividuos(prueba, :) = mejorIndividuo;

            % ========================================================
            % MOSTRAR RESULTADOS DE ESTA PRUEBA
            % ========================================================

            fprintf('Tiempo de ejecución: %.6f segundos\n', ...
                tiempoEjecucion);

            fprintf('Mejor valor f(X): %.4f\n', ...
                mejorGlobal);

            fprintf('Mejor individuo X:\n');

            disp(mejorIndividuo);

        end

        % ============================================================
        % ESTADÍSTICAS DE LAS PRUEBAS
        % ============================================================

        % Promedio de los mejores resultados obtenidos
        promedio = mean(mejoresPruebas);

        % Desviación estándar ENTRE LAS PRUEBAS
        desviacion = std(mejoresPruebas);

        % Tiempo promedio de ejecución
        tiempoPromedio = mean(tiemposPruebas);

        % Mejor resultado obtenido entre todas las pruebas
        [mejorValorGlobal, indiceMejorPrueba] = ...
            min(mejoresPruebas);

        mejorIndividuoGlobal = ...
            mejoresIndividuos(indiceMejorPrueba, :);

        % ============================================================
        % GUARDAR RESULTADOS
        % ============================================================

        resultados(metodo).seleccion = nombre;

        % Datos individuales de cada prueba
        resultados(metodo).pruebas = struct();

        for prueba = 1:nPruebas

            resultados(metodo).pruebas(prueba).numero = prueba;

            resultados(metodo).pruebas(prueba).tiempo = ...
                tiemposPruebas(prueba);

            resultados(metodo).pruebas(prueba).mejorValor = ...
                mejoresPruebas(prueba);

            resultados(metodo).pruebas(prueba).mejorIndividuo = ...
                mejoresIndividuos(prueba, :);

            resultados(metodo).pruebas(prueba).mejoresIteraciones = ...
                mejoresIteraciones(:, prueba);

        end

        % Estadísticas generales del método
        resultados(metodo).tiempo = tiempoPromedio;

        resultados(metodo).mejorValor = mejorValorGlobal;

        resultados(metodo).mejorIndividuo = mejorIndividuoGlobal;

        resultados(metodo).promedio = promedio;

        resultados(metodo).desviacionEstandar = desviacion;

        resultados(metodo).mejoresPruebas = mejoresPruebas;

        resultados(metodo).tiemposPruebas = tiemposPruebas;

        resultados(metodo).mejoresIndividuos = mejoresIndividuos;

        resultados(metodo).mejoresIteraciones = mejoresIteraciones;

        % ============================================================
        % MOSTRAR ESTADÍSTICAS DEL MÉTODO
        % ============================================================

        fprintf('\n=============================================\n');
        fprintf('RESUMEN DEL MÉTODO: %s\n', nombre);
        fprintf('=============================================\n');

        fprintf('Promedio f(X): %.4f\n', promedio);

        fprintf('Desviación estándar: %.6f\n', ...
            desviacion);

        fprintf('Tiempo promedio: %.6f segundos\n', ...
            tiempoPromedio);

        fprintf('Mejor resultado de todas las pruebas: %.4f\n', ...
            mejorValorGlobal);

        fprintf('Individuo que produce el mejor resultado:\n');

        disp(mejorIndividuoGlobal);

    end

    % ============================================================
    % TABLA RESUMEN
    % ============================================================

    fprintf('\n\n============================================================\n');
    fprintf('                 RESULTADOS FINALES\n');
    fprintf('============================================================\n');

    fprintf('%-15s %-15s %-15s %-15s %-15s\n', ...
        'Selección', ...
        'Tiempo (s)', ...
        'Promedio f(X)', ...
        'Mejor f(X)', ...
        'Desv. estándar');

    fprintf('------------------------------------------------------------\n');

    for i = 1:nMetodos

        fprintf('%-15s %-15.6f %-15.4f %-15.4f %-15.6f\n', ...
            resultados(i).seleccion, ...
            resultados(i).tiempo, ...
            resultados(i).promedio, ...
            resultados(i).mejorValor, ...
            resultados(i).desviacionEstandar);

    end

    fprintf('============================================================\n');

end
%}

%{
function resultados = pruebaAlgoritmoGeneticoViajeroTorneo( ...
        nPoblacion, nIteraciones, nPruebas)

    % ============================================================
    % PRUEBA DEL ALGORITMO GENÉTICO - PROBLEMA DEL VIAJERO
    %
    % Método de selección: TORNEO
    % Método de cruce: OX
    % Mutación: NO SE APLICA
    %
    % Permite estudiar el efecto del número de iteraciones
    % mediante varias pruebas independientes.
    %
    % Parámetros:
    %   nPoblacion   -> tamaño de la población
    %   nIteraciones -> número de iteraciones
    %   nPruebas    -> número de pruebas independientes
    %
    % Resultados:
    %   - Tiempo de ejecución de cada prueba
    %   - Mejor f(X) de cada prueba
    %   - Mejor individuo X de cada prueba
    %   - Promedio de los mejores resultados
    %   - Desviación estándar entre las pruebas
    %   - Mejor resultado global
    % ============================================================


    % ============================================================
    % VALORES POR DEFECTO
    % ============================================================

    if nargin < 1 || isempty(nPoblacion)
        nPoblacion = 48;
    end

    if nargin < 2 || isempty(nIteraciones)
        nIteraciones = 200;
    end

    if nargin < 3 || isempty(nPruebas)
        nPruebas = 5;
    end


    % ============================================================
    % VALIDACIÓN
    % ============================================================

    validateattributes(nPoblacion, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    validateattributes(nIteraciones, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    validateattributes(nPruebas, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});


    % La población debe ser par para realizar el apareamiento
    if mod(nPoblacion, 2) ~= 0
        error('nPoblacion debe ser un número par.');
    end


    % ============================================================
    % CONFIGURACIÓN DEL MÉTODO
    % ============================================================

    nombreSeleccion = 'Torneo';

    % ============================================================
    % VECTORES PARA ALMACENAR LOS RESULTADOS
    % ============================================================

    tiemposPruebas = zeros(nPruebas, 1);

    mejoresPruebas = zeros(nPruebas, 1);

    % Cada fila corresponde al mejor individuo de una prueba
    mejoresIndividuos = zeros(nPruebas, 13);

    % Mejor resultado encontrado en cada iteración
    % de cada prueba
    mejoresIteraciones = zeros(nIteraciones, nPruebas);


    % ============================================================
    % EJECUCIÓN DE LAS PRUEBAS
    % ============================================================

    for prueba = 1:nPruebas

        fprintf('\n=============================================\n');
        fprintf('SELECCIÓN: %s\n', nombreSeleccion);
        fprintf('PRUEBA: %d de %d\n', prueba, nPruebas);
        fprintf('ITERACIONES: %d\n', nIteraciones);
        fprintf('=============================================\n');


        tic;


        % ========================================================
        % VARIABLES DE LA PRUEBA
        % ========================================================

        mejorGlobal = Inf;
        mejorIndividuo = [];


        % ========================================================
        % 1. GENERACIÓN DE POBLACIÓN INICIAL
        % ========================================================

        poblacion = generarPoblacionInicial(nPoblacion);


        % ========================================================
        % 2. ITERACIONES DEL ALGORITMO GENÉTICO
        % ========================================================

        for iteracion = 1:nIteraciones


            % ====================================================
            % EVALUACIÓN DE LA POBLACIÓN
            % ====================================================

            aptitud = arrayfun(@(i) ...
                ProblemaViajeroFcn(poblacion(i, :)), ...
                (1:nPoblacion).');


            % ====================================================
            % SELECCIÓN POR TORNEO
            % ====================================================

            [padres, ~] = seleccionTorneo( ...
                poblacion, ...
                aptitud, ...
                4, ...       % Tamaño del torneo
                2, ...       % Número de ganadores
                'min');      % Problema de minimización


            % ====================================================
            % CRUCE OX
            % ====================================================

            nPadres = size(padres, 1);

            hijos = zeros(nPadres, 13);


            for i = 1:2:nPadres

                padre1 = padres(i, :);
                padre2 = padres(i + 1, :);

                [hijo1, hijo2] = cruceOX(padre1, padre2);

                hijos(i, :) = hijo1;
                hijos(i + 1, :) = hijo2;

            end


            % ====================================================
            % FORMACIÓN DE LA NUEVA POBLACIÓN
            % ====================================================

            poblacionNueva = [padres; hijos];


            % ====================================================
            % VERIFICACIÓN DEL TAMAÑO
            % ====================================================

            if size(poblacionNueva, 1) ~= nPoblacion

                error(['El método de torneo produjo una población ', ...
                    'de %d individuos. Se esperaban %d.'], ...
                    size(poblacionNueva, 1), ...
                    nPoblacion);

            end


            % ====================================================
            % EVALUACIÓN DE LA NUEVA POBLACIÓN
            % ====================================================

            aptitudNueva = arrayfun(@(i) ...
                ProblemaViajeroFcn(poblacionNueva(i, :)), ...
                (1:nPoblacion).');


            % ====================================================
            % MEJOR RESULTADO DE LA ITERACIÓN
            % ====================================================

            [mejorIteracion, indiceMejor] = min(aptitudNueva);


            % Guardar mejor resultado de esta iteración
            mejoresIteraciones(iteracion, prueba) = ...
                mejorIteracion;


            % ====================================================
            % ACTUALIZAR MEJOR RESULTADO GLOBAL DE LA PRUEBA
            % ====================================================

            if mejorIteracion < mejorGlobal

                mejorGlobal = mejorIteracion;

                mejorIndividuo = ...
                    poblacionNueva(indiceMejor, :);

            end


            % ====================================================
            % NUEVA GENERACIÓN
            % ====================================================

            poblacion = poblacionNueva;

        end


        % ========================================================
        % FINALIZACIÓN DE LA PRUEBA
        % ========================================================

        tiempoEjecucion = toc;


        % ========================================================
        % GUARDAR RESULTADOS DE LA PRUEBA
        % ========================================================

        tiemposPruebas(prueba) = ...
            tiempoEjecucion;

        mejoresPruebas(prueba) = ...
            mejorGlobal;

        mejoresIndividuos(prueba, :) = ...
            mejorIndividuo;


        % ========================================================
        % MOSTRAR RESULTADOS DE LA PRUEBA
        % ========================================================

        fprintf('\nTiempo de ejecución: %.6f segundos\n', ...
            tiempoEjecucion);

        fprintf('Mejor valor f(X): %.4f\n', ...
            mejorGlobal);

        fprintf('Mejor individuo X:\n');

        disp(mejorIndividuo);

    end


    % ============================================================
    % ESTADÍSTICAS DE LAS PRUEBAS
    % ============================================================

    % Promedio de los mejores resultados de las pruebas
    promedio = mean(mejoresPruebas);


    % ============================================================
    % DESVIACIÓN ESTÁNDAR
    %
    % Se calcula ENTRE LAS PRUEBAS.
    %
    % Ejemplo:
    % [430 425 418 421 420]
    %
    % La desviación mide qué tanto varían los resultados
    % finales entre las diferentes ejecuciones.
    % ============================================================

    desviacion = std(mejoresPruebas);


    % Tiempo promedio
    tiempoPromedio = mean(tiemposPruebas);


    % ============================================================
    % MEJOR RESULTADO DE TODAS LAS PRUEBAS
    % ============================================================

    [mejorValorGlobal, indiceMejorPrueba] = ...
        min(mejoresPruebas);


    mejorIndividuoGlobal = ...
        mejoresIndividuos(indiceMejorPrueba, :);


    % ============================================================
    % GUARDAR RESULTADOS
    % ============================================================

    resultados.seleccion = nombreSeleccion;

    resultados.nPoblacion = nPoblacion;

    resultados.nIteraciones = nIteraciones;

    resultados.nPruebas = nPruebas;


    % ------------------------------------------------------------
    % RESULTADOS INDIVIDUALES DE CADA PRUEBA
    % ------------------------------------------------------------

    resultados.pruebas = struct();


    for prueba = 1:nPruebas

        resultados.pruebas(prueba).numero = ...
            prueba;

        resultados.pruebas(prueba).tiempo = ...
            tiemposPruebas(prueba);

        resultados.pruebas(prueba).mejorValor = ...
            mejoresPruebas(prueba);

        resultados.pruebas(prueba).mejorIndividuo = ...
            mejoresIndividuos(prueba, :);

        resultados.pruebas(prueba).mejoresIteraciones = ...
            mejoresIteraciones(:, prueba);

    end


    % ------------------------------------------------------------
    % ESTADÍSTICAS GENERALES
    % ------------------------------------------------------------

    resultados.tiempoPromedio = ...
        tiempoPromedio;

    resultados.promedio = ...
        promedio;

    resultados.mejorValor = ...
        mejorValorGlobal;

    resultados.mejorIndividuo = ...
        mejorIndividuoGlobal;

    resultados.desviacionEstandar = ...
        desviacion;


    % ------------------------------------------------------------
    % DATOS COMPLETOS
    % ------------------------------------------------------------

    resultados.tiemposPruebas = ...
        tiemposPruebas;

    resultados.mejoresPruebas = ...
        mejoresPruebas;

    resultados.mejoresIndividuos = ...
        mejoresIndividuos;

    resultados.mejoresIteraciones = ...
        mejoresIteraciones;


    % ============================================================
    % TABLA RESUMEN
    % ============================================================

    fprintf('\n\n============================================================\n');
    fprintf('       RESULTADOS - TORNEO + CRUCE OX\n');
    fprintf('============================================================\n');

    fprintf('Número de iteraciones: %d\n', ...
        nIteraciones);

    fprintf('Número de pruebas: %d\n', ...
        nPruebas);

    fprintf('------------------------------------------------------------\n');

    fprintf('%-15s %-15s %-15s %-15s %-15s\n', ...
        'Prueba', ...
        'Tiempo (s)', ...
        'Mejor f(X)', ...
        'Desv. estándar', ...
        'Iteraciones');

    fprintf('------------------------------------------------------------\n');


    % ------------------------------------------------------------
    % Mostrar resultados individuales
    % ------------------------------------------------------------

    for prueba = 1:nPruebas

        fprintf('%-15d %-15.6f %-15.4f %-15s %-15d\n', ...
            prueba, ...
            tiemposPruebas(prueba), ...
            mejoresPruebas(prueba), ...
            '-', ...
            nIteraciones);

    end


    fprintf('------------------------------------------------------------\n');


    % ------------------------------------------------------------
    % Estadísticas globales
    % ------------------------------------------------------------

    fprintf('%-15s %-15.6f %-15.4f %-15.6f %-15d\n', ...
        'PROMEDIO', ...
        tiempoPromedio, ...
        promedio, ...
        desviacion, ...
        nIteraciones);


    fprintf('============================================================\n');

    fprintf('\nMejor resultado global: %.4f\n', ...
        mejorValorGlobal);

    fprintf('Obtenido en la prueba: %d\n', ...
        indiceMejorPrueba);

    fprintf('Individuo X que produce el mejor resultado:\n');

    disp(mejorIndividuoGlobal);

end
%}

function resultados = pruebaAlgoritmoGeneticoViajeroTorneoMutacion( ...
        nPoblacion, nIteraciones, nPruebas, probMutacion)

    % ============================================================
    % PRUEBA FINAL DEL ALGORITMO GENÉTICO - PROBLEMA DEL VIAJERO
    %
    % Método de selección: TORNEO
    % Método de cruce: OX
    % Método de mutación: INTERCAMBIO
    %
    % Parámetros:
    %   nPoblacion   -> tamaño de la población
    %   nIteraciones -> número de iteraciones
    %   nPruebas    -> número de pruebas independientes
    %   probMutacion -> probabilidad de mutación de cada hijo
    %
    % Resultados:
    %   - Tiempo de cada prueba
    %   - Mejor f(X) de cada prueba
    %   - Mejor individuo X de cada prueba
    %   - Promedio de los mejores resultados
    %   - Desviación estándar entre las pruebas
    %   - Mejor resultado global
    %   - Individuo que produce el mejor resultado
    % ============================================================


    % ============================================================
    % VALORES POR DEFECTO
    % ============================================================

    if nargin < 1 || isempty(nPoblacion)
        nPoblacion = 48;
    end

    if nargin < 2 || isempty(nIteraciones)
        nIteraciones = 200;
    end

    if nargin < 3 || isempty(nPruebas)
        nPruebas = 5;
    end

    if nargin < 4 || isempty(probMutacion)
        probMutacion = 0.50;
    end


    % ============================================================
    % VALIDACIÓN DE PARÁMETROS
    % ============================================================

    validateattributes(nPoblacion, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    validateattributes(nIteraciones, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    validateattributes(nPruebas, {'numeric'}, ...
        {'scalar', 'integer', 'positive'});

    validateattributes(probMutacion, {'numeric'}, ...
        {'scalar', '>=', 0, '<=', 1});


    % La población debe ser par
    if mod(nPoblacion, 2) ~= 0
        error('nPoblacion debe ser un número par.');
    end


    % ============================================================
    % CONFIGURACIÓN
    % ============================================================

    nombreSeleccion = 'Torneo';
    nombreCruce = 'OX';
    nombreMutacion = 'Intercambio';


    % ============================================================
    % VECTORES PARA ALMACENAR LOS RESULTADOS
    % ============================================================

    tiemposPruebas = zeros(nPruebas, 1);

    mejoresPruebas = zeros(nPruebas, 1);

    % Cada fila almacena el mejor individuo de una prueba
    mejoresIndividuos = zeros(nPruebas, 13);

    % Mejor resultado encontrado en cada iteración
    mejoresIteraciones = zeros(nIteraciones, nPruebas);


    % ============================================================
    % EJECUCIÓN DE LAS PRUEBAS INDEPENDIENTES
    % ============================================================

    for prueba = 1:nPruebas

        fprintf('\n=============================================\n');
        fprintf('PRUEBA %d DE %d\n', prueba, nPruebas);
        fprintf('Selección: %s\n', nombreSeleccion);
        fprintf('Cruce: %s\n', nombreCruce);
        fprintf('Mutación: %s\n', nombreMutacion);
        fprintf('Probabilidad de mutación: %.2f\n', probMutacion);
        fprintf('Iteraciones: %d\n', nIteraciones);
        fprintf('=============================================\n');


        tic;


        % ========================================================
        % VARIABLES DE LA PRUEBA
        % ========================================================

        mejorGlobal = Inf;
        mejorIndividuo = [];


        % ========================================================
        % 1. GENERACIÓN DE LA POBLACIÓN INICIAL
        % ========================================================

        poblacion = generarPoblacionInicial(nPoblacion);


        % ========================================================
        % 2. ITERACIONES DEL ALGORITMO GENÉTICO
        % ========================================================

        for iteracion = 1:nIteraciones


            % ====================================================
            % EVALUACIÓN DE LA POBLACIÓN
            % ====================================================

            aptitud = arrayfun(@(i) ...
                ProblemaViajeroFcn(poblacion(i, :)), ...
                (1:nPoblacion).');


            % ====================================================
            % SELECCIÓN POR TORNEO
            % ====================================================

            [padres, ~] = seleccionTorneo( ...
                poblacion, ...
                aptitud, ...
                4, ...       % Tamaño del torneo
                2, ...       % Número de ganadores
                'min');      % Problema de minimización


            % ====================================================
            % CRUCE OX
            % ====================================================

            nPadres = size(padres, 1);

            hijos = zeros(nPadres, 13);


            for i = 1:2:nPadres

                padre1 = padres(i, :);
                padre2 = padres(i + 1, :);

                [hijo1, hijo2] = cruceOX(padre1, padre2);

                hijos(i, :) = hijo1;
                hijos(i + 1, :) = hijo2;

            end


            % ====================================================
            % MUTACIÓN POR INTERCAMBIO
            % ====================================================
            %
            % Cada hijo tiene una probabilidad probMutacion
            % de sufrir una mutación.
            %
            % La función mutacionIntercambio ya implementada
            % selecciona aleatoriamente dos posiciones de la ruta
            % y las intercambia.

            for i = 1:nPadres

                if rand < probMutacion

                    hijos(i, :) = ...
                        mutacionIntercambio(hijos(i, :));

                end

            end


            % ====================================================
            % FORMACIÓN DE LA NUEVA POBLACIÓN
            % ====================================================

            poblacionNueva = [padres; hijos];


            % ====================================================
            % VERIFICACIÓN DEL TAMAÑO DE LA POBLACIÓN
            % ====================================================

            if size(poblacionNueva, 1) ~= nPoblacion

                error(['El algoritmo produjo una población de ', ...
                    '%d individuos. Se esperaban %d.'], ...
                    size(poblacionNueva, 1), ...
                    nPoblacion);

            end


            % ====================================================
            % EVALUACIÓN DE LA NUEVA POBLACIÓN
            % ====================================================

            aptitudNueva = arrayfun(@(i) ...
                ProblemaViajeroFcn(poblacionNueva(i, :)), ...
                (1:nPoblacion).');


            % ====================================================
            % MEJOR RESULTADO DE LA ITERACIÓN
            % ====================================================

            [mejorIteracion, indiceMejor] = min(aptitudNueva);


            % Guardar el mejor resultado de esta iteración

            mejoresIteraciones(iteracion, prueba) = ...
                mejorIteracion;


            % ====================================================
            % ACTUALIZAR MEJOR RESULTADO GLOBAL
            % ====================================================

            if mejorIteracion < mejorGlobal

                mejorGlobal = mejorIteracion;

                mejorIndividuo = ...
                    poblacionNueva(indiceMejor, :);

            end


            % ====================================================
            % NUEVA GENERACIÓN
            % ============================================================

            poblacion = poblacionNueva;

        end


        % ========================================================
        % FINALIZACIÓN DE LA PRUEBA
        % ========================================================

        tiempoEjecucion = toc;


        % ========================================================
        % GUARDAR RESULTADOS DE LA PRUEBA
        % ========================================================

        tiemposPruebas(prueba) = ...
            tiempoEjecucion;

        mejoresPruebas(prueba) = ...
            mejorGlobal;

        mejoresIndividuos(prueba, :) = ...
            mejorIndividuo;


        % ========================================================
        % MOSTRAR RESULTADOS DE LA PRUEBA
        % ========================================================

        fprintf('\nResultado de la prueba %d:\n', prueba);

        fprintf('Tiempo de ejecución: %.6f segundos\n', ...
            tiempoEjecucion);

        fprintf('Mejor valor f(X): %.4f\n', ...
            mejorGlobal);

        fprintf('Mejor individuo X:\n');

        disp(mejorIndividuo);

    end


    % ============================================================
    % ESTADÍSTICAS DE LAS PRUEBAS
    % ============================================================

    % Promedio de los mejores resultados obtenidos
    promedio = mean(mejoresPruebas);


    % Desviación estándar ENTRE las pruebas
    %
    % Esto mide cuánto varían los resultados finales
    % entre las diferentes ejecuciones independientes.

    desviacion = std(mejoresPruebas);


    % Tiempo promedio de ejecución
    tiempoPromedio = mean(tiemposPruebas);


    % ============================================================
    % MEJOR RESULTADO DE TODAS LAS PRUEBAS
    % ============================================================

    [mejorValorGlobal, indiceMejorPrueba] = ...
        min(mejoresPruebas);


    mejorIndividuoGlobal = ...
        mejoresIndividuos(indiceMejorPrueba, :);


    % ============================================================
    % GUARDAR RESULTADOS EN LA ESTRUCTURA
    % ============================================================

    resultados.seleccion = nombreSeleccion;

    resultados.cruce = nombreCruce;

    resultados.mutacion = nombreMutacion;

    resultados.probMutacion = probMutacion;

    resultados.nPoblacion = nPoblacion;

    resultados.nIteraciones = nIteraciones;

    resultados.nPruebas = nPruebas;


    % ============================================================
    % RESULTADOS INDIVIDUALES DE CADA PRUEBA
    % ============================================================

    resultados.pruebas = struct();


    for prueba = 1:nPruebas

        resultados.pruebas(prueba).numero = ...
            prueba;

        resultados.pruebas(prueba).tiempo = ...
            tiemposPruebas(prueba);

        resultados.pruebas(prueba).mejorValor = ...
            mejoresPruebas(prueba);

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
        mejorValorGlobal;

    resultados.mejorIndividuo = ...
        mejorIndividuoGlobal;

    resultados.desviacionEstandar = ...
        desviacion;


    % ============================================================
    % DATOS COMPLETOS
    % ============================================================

    resultados.tiemposPruebas = ...
        tiemposPruebas;

    resultados.mejoresPruebas = ...
        mejoresPruebas;

    resultados.mejoresIndividuos = ...
        mejoresIndividuos;

    resultados.mejoresIteraciones = ...
        mejoresIteraciones;


    % ============================================================
    % TABLA 1: RESULTADOS DE CADA PRUEBA
    % ============================================================

    fprintf('\n\n');
    fprintf('====================================================================\n');
    fprintf('       RESULTADOS INDIVIDUALES - TORNEO + OX + MUTACIÓN\n');
    fprintf('====================================================================\n');

    fprintf('%-10s %-15s %-15s\n', ...
        'Prueba', ...
        'Tiempo (s)', ...
        'Mejor f(X)');

    fprintf('--------------------------------------------------------------------\n');


    for prueba = 1:nPruebas

        fprintf('%-10d %-15.6f %-15.4f\n', ...
            prueba, ...
            tiemposPruebas(prueba), ...
            mejoresPruebas(prueba));

    end


    fprintf('====================================================================\n');


    % ============================================================
    % TABLA 2: MEJOR INDIVIDUO DE CADA PRUEBA
    % ============================================================

    fprintf('\n');
    fprintf('====================================================================\n');
    fprintf('           MEJORES INDIVIDUOS EN CADA PRUEBA\n');
    fprintf('====================================================================\n');


    for prueba = 1:nPruebas

        fprintf('Prueba %d\n', prueba);

        fprintf('Mejor f(X): %.4f\n', ...
            mejoresPruebas(prueba));

        fprintf('Individuo X: ');

        fprintf('%d ', mejoresIndividuos(prueba, :));

        fprintf('\n');

        fprintf('--------------------------------------------------------------------\n');

    end


    % ============================================================
    % TABLA 3: RESUMEN ESTADÍSTICO
    % ============================================================

    fprintf('\n');
    fprintf('====================================================================\n');
    fprintf('                    RESUMEN ESTADÍSTICO\n');
    fprintf('====================================================================\n');

    fprintf('%-25s %.6f segundos\n', ...
        'Tiempo promedio:', ...
        tiempoPromedio);

    fprintf('%-25s %.4f\n', ...
        'Promedio mejor f(X):', ...
        promedio);

    fprintf('%-25s %.6f\n', ...
        'Desviación estándar:', ...
        desviacion);

    fprintf('%-25s %.4f\n', ...
        'Mejor f(X) global:', ...
        mejorValorGlobal);

    fprintf('%-25s %d\n', ...
        'Prueba del mejor resultado:', ...
        indiceMejorPrueba);

    fprintf('--------------------------------------------------------------------\n');

    fprintf('Individuo X del mejor resultado:\n');

    disp(mejorIndividuoGlobal);

    fprintf('====================================================================\n');


    % ============================================================
    % TABLA FINAL PARA PRESENTAR EN EL INFORME
    % ============================================================

    fprintf('\n');
    fprintf('====================================================================\n');
    fprintf('                     TABLA FINAL\n');
    fprintf('====================================================================\n');

    fprintf('%-15s %-15s %-15s %-15s\n', ...
        'Selección', ...
        'Cruce', ...
        'Mutación', ...
        'Iteraciones');

    fprintf('%-15s %-15s %-15s %-15d\n', ...
        nombreSeleccion, ...
        nombreCruce, ...
        nombreMutacion, ...
        nIteraciones);

    fprintf('\n');

    fprintf('%-25s %.4f\n', ...
        'Mejor valor f(X):', ...
        mejorValorGlobal);

    fprintf('%-25s %.6f\n', ...
        'Desviación estándar:', ...
        desviacion);

    fprintf('%-25s %.6f s\n', ...
        'Tiempo promedio:', ...
        tiempoPromedio);

    fprintf('====================================================================\n');

end

% FUNCIÓN OBJETIVO PROBLEMA DEL VIAJERO
function tiempo = ProblemaViajeroFcn(ruta)

    if ~isnumeric(ruta) || numel(ruta) ~= 13 || ...
            any(~isfinite(ruta)) || ...
            any(ruta ~= fix(ruta)) || ...
            ~isequal(sort(ruta(:)).', 1:13)

        tiempo = NaN;

        return

    end


    tiempos = [ ...
         0  10  35  29  16  30  40  27  56  44  67  54  81;
         6   0  32  31  16  32  34  28  52  44  63  56  83;
        34  32   0  29  45  58  35  57  26  73  91  83 110;
        29  29  28   0  32  47  57  31  49  61  67  70  99;
        18  18  46  33   0  23  52  19  68  39  54  41  69;
        30  30  58  46  25   0  46  36  79  39  71  62  90;
        40  37  36  59  52  54   0  64  61  80 104  89 117;
        32  32  57  32  18  36  65   0  82  50  41  51  82;
        55  52  23  48  67  80  56  73   0  95 116 101 130;
        47  47  76  62  42  37  73  53  97   0 102  81 111;
        79  79 106  80  66  87 110  59 148 101   0  97 100;
        59  59  86  74  44  65  90  55 107  80  93   0  29;
        89  89 116 104  74  96 119  86 137 110 103  33   0];


    ruta = ruta(:).';


    tiempo = sum( ...
        tiempos( ...
        sub2ind( ...
        [13, 13], ...
        ruta(1:end-1), ...
        ruta(2:end))));

end

% GENERACIÓN DE POBLACIÓN INICIAL PROBLEMA DEL VIAJERO
function poblacion = generarPoblacionInicial(n)

    validateattributes( ...
        n, ...
        {'numeric'}, ...
        {'scalar', 'integer', 'positive'});


    [~, poblacion] = sort(rand(n, 13), 2);

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

function [hijo1, hijo2] = cruceOX(padre1, padre2)

    validateattributes(padre1, {'numeric'}, {'vector', 'nonempty'});
    validateattributes(padre2, {'numeric'}, {'vector', 'nonempty'});

    padre1 = padre1(:).';
    padre2 = padre2(:).';

    if numel(padre1) ~= numel(padre2) || ...
            any(~isfinite([padre1, padre2])) || ...
            any([padre1, padre2] ~= fix([padre1, padre2])) || ...
            ~isequal(sort(padre1), sort(padre2)) || ...
            numel(unique(padre1)) ~= numel(padre1)

        error('Los padres deben ser permutaciones válidas del mismo conjunto.');
    end

    n = numel(padre1);

    cortes = sort(randperm(n, 2));
    inicio = cortes(1);
    fin = cortes(2);

    hijo1 = zeros(1, n);
    hijo2 = zeros(1, n);

    hijo1(inicio:fin) = padre1(inicio:fin);
    hijo2(inicio:fin) = padre2(inicio:fin);

    restantes1 = padre2(~ismember(padre2, hijo1(inicio:fin)));
    restantes2 = padre1(~ismember(padre1, hijo2(inicio:fin)));

    posiciones = [fin + 1:n, 1:inicio - 1];

    hijo1(posiciones) = restantes1;
    hijo2(posiciones) = restantes2;

end

function individuoMutado = mutacionIntercambio(individuo)

    validateattributes(individuo, {'numeric'}, {'vector', 'nonempty'});

    individuo = individuo(:).';

    if numel(individuo) ~= 13 || ...
            any(~isfinite(individuo)) || ...
            any(individuo ~= fix(individuo)) || ...
            ~isequal(sort(individuo), 1:13)

        error('El individuo debe ser una permutación válida de 1:13.');
    end

    posiciones = randperm(13, 2);
    individuoMutado = individuo;
    individuoMutado(posiciones) = individuoMutado(fliplr(posiciones));

end




