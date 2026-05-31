# 🧠 Interfaz de Filtrado EEG y Diagnóstico de Epilepsia (MATLAB)

Este proyecto consiste en una aplicación de interfaz gráfica (GUI) desarrollada en MATLAB para el procesamiento avanzado de señales electroencefalográficas (EEG) y la detección automática, en tiempo real, de eventos epileptiformes (crisis epilépticas).

El sistema carga registros médicos en formato `.edf`, aplica un pipeline de limpieza de ruido mediante filtros digitales, separa las bandas de frecuencia cerebrales usando la Transformada Wavelet Discreta, y emite un diagnóstico clínico computacional basado en la energía relativa de la señal.
![Captura de pantalla del Analizador EEG detectando una crisis](analizador_eeg_5min.png)

## 🗂️ Base de Datos Empleada

Para el desarrollo y prueba de este algoritmo se ha utilizado la **Siena Scalp EEG Database**. Esta base de datos pública de PhysioNet recoge registros de 14 pacientes diagnosticados con epilepsia adquiridos en la Unidad de Neurología y Neurofisiología de la Universidad de Siena. La cohorte incluye a 9 hombres (entre 25 y 71 años) y 5 mujeres (entre 20 y 58 años). La frecuencia de muestreo de los registros procesados es de 512 Hz.

## ⚙️ Pipeline de Procesado de Señal

Para asegurar una lectura precisa antes del análisis, el sistema limpia la señal bruta aplicando las siguientes técnicas:

1. **Eliminación de la componente continua (DC):** Se sustrae la media aritmética de la señal original para centrarla en cero.
2. **Filtro Notch (Rechazo de banda):** Se aplica para eliminar la interferencia electromagnética de 50 Hz proveniente de la red eléctrica.
3. **Filtro Paso Alto (0.5 Hz):** Diseñado para suprimir los artefactos de baja frecuencia asociados a los movimientos del paciente y la respiración.
4. **Descomposición Wavelet:** Se aplica la Transformada Wavelet para separar el EEG limpio en las bandas de frecuencia cerebrales fisiológicas (Gamma, Beta, Alpha, Theta y Delta).

## 🩺 Algoritmo de Detección de Epilepsia

La epilepsia es un trastorno cerebral caracterizado por convulsiones repetidas generadas por actividad eléctrica anormal y descontrolada de las neuronas. Ocurre cuando el tejido cerebral se vuelve demasiado excitable.

Para detectar las crisis en el momento en el que suceden, el algoritmo evalúa la señal basándose en dos criterios clínicos rigurosos:

### 1. Criterio Energético (Dominancia Delta)
El algoritmo calcula la energía relativa de la banda Delta en ventanas de 1 segundo de duración. La potencia relativa se obtiene dividiendo la potencia media de la banda Delta entre la potencia total de todas las bandas ($P_{relativa} = \frac{P_{delta}}{P_{total}}$). 

Basándose en la literatura científica (*"Analysis of EEG records in an epileptic patient using wavelet transform"* por Adeli et al.), un valor elevado indica que la actividad lenta domina toda la señal, lo que es característico de una crisis epiléptica. Se ha establecido un umbral del 60% para clasificar un segundo como "patológico", descartando así falsos positivos por sueño natural o movimientos oculares (donde la dominancia Delta es normal pero inferior al 60%).

### 2. Criterio Temporal (Regla de los 10 segundos)
Alcanzar el umbral energético no es condición suficiente para considerar una crisis. El sistema almacena las evaluaciones de cada ventana temporal en un vector binario (0 o 1). 

Siguiendo las recomendaciones de la Federación Internacional de Neurofisiología Clínica (IFCN), se exige que la dominancia de la banda Delta se mantenga durante un periodo ininterrumpido de, al menos, 10 segundos para diagnosticar el evento como una crisis epiléptica real. Si el contador de actividad anómala detecta que el evento finaliza antes de los 10 segundos, el contador se resetea y descarta el falso positivo. En caso afirmativo, se extrae la duración total y las marcas de tiempo para generar el informe. De esta forma, se construye un algoritmo de detección en tiempo real.

