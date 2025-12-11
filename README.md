# Control de Robot Móvil Autónomo - Resolución de Laberintos

Este proyecto implementa el sistema de control para un robot autónomo basado en la placa **Cora Z7**. [cite_start]El objetivo principal es que el robot navegue de forma autónoma por un laberinto, encontrando la salida utilizando algoritmos de navegación y sensorización avanzada[cite: 1, 5].

## 🎯 Objetivo del Proyecto

[cite_start]El robot debe ser capaz de navegar por un laberinto desconocido y encontrar la salida marcada por una línea negra en el suelo[cite: 5, 16].

**Estrategia de Navegación:**
* [cite_start]**Algoritmo de la mano derecha:** El robot gira a la derecha en las esquinas y mantiene una distancia constante con la pared derecha[cite: 10, 11].
* [cite_start]**Corrección de trayectoria:** Si el robot se aleja o se acerca demasiado a la pared, rectifica su posición basándose en los sensores[cite: 13, 14].
* [cite_start]**Detección de salida:** Se identifica el final del laberinto mediante sensores infrarrojos inferiores[cite: 216].

## 🛠 Hardware

[cite_start]El sistema se ejecuta directamente sobre el hardware (Bare Metal) sin sistema operativo, utilizando la placa **Digilent Cora Z7**[cite: 34, 6].

### Sensores y Actuadores
* [cite_start]**Placa Base:** Cora Z7 (Dual Core ARM/FPGA)[cite: 6].
* [cite_start]**Sensores Frontales (IRF):** 2x ST188 fotoeléctricos infrarrojos para detección de obstáculos[cite: 45].
* [cite_start]**Sensores Inferiores (IRI):** 5x ITR20001/T para seguimiento de línea y detección de salida[cite: 46].
* [cite_start]**Sensor Lateral:** 1x Ultrasonidos HC-SR04 para medir distancia a la pared[cite: 47].
* [cite_start]**Visualización:** Display de 7 segmentos (PmodSSD) para mostrar el tiempo de ejecución[cite: 48].
* [cite_start]**Actuadores:** Motores DC controlados por PWM[cite: 40].

## 💻 Arquitectura Software

[cite_start]El proyecto está desarrollado en **Ada** utilizando el perfil **Ravenscar** para sistemas de tiempo real crítico[cite: 161, 162]. Se hace uso de la capacidad multicore de la Cora Z7 dividiendo la carga de trabajo:

| Núcleo (Core) | Responsabilidades |
| :--- | :--- |
| **CORE 0** | **Control PWM:** Gestión de motores ($T_{ON}/T_{OFF}$). [cite_start]<br> **Máquina de Estados:** Lógica de decisión de navegación[cite: 25, 27]. |
| **CORE 1** | **Sensorización:** Lectura y filtrado de sensores. [cite_start]<br> **Temporización:** Control del cronómetro en el Display 7S[cite: 26, 28]. |

**Sincronización:**
[cite_start]La comunicación entre tareas y núcleos se realiza mediante un **Objeto Protegido** (`Datos_Sensores`) que almacena de forma segura los valores de distancia y estado de los sensores[cite: 38, 182].

## 📂 Estructura del Código

* [cite_start]`demo.adb`: Programa principal que orquesta las tareas[cite: 165].
* [cite_start]`demo.gpr`: Fichero de proyecto GNAT para compilación (target `arm-eabi`)[cite: 160].
* [cite_start]`paquete gpio`: Gestión de entrada/salida de propósito general (Leds, Botones, Sensores IR) mapeados en memoria[cite: 167, 86].
* [cite_start]`paquete uart`: Comunicación serie entre la placa y el host[cite: 166].

## 🚀 Estado del Proyecto (Roadmap)

El desarrollo se divide en sesiones incrementales:

- [x] [cite_start]**Sesión 0:** Configuración del entorno y "Hola Mundo"[cite: 149].
- [ ] [cite_start]**Sesión 1 (Actual):** Definición de la Máquina de Estados e implementación de lectura de sensores (IR Frontales e Inferiores)[cite: 156].
- [ ] [cite_start]**Sesión 2:** Integración de sensorización en la máquina de estados[cite: 152].
- [ ] [cite_start]**Sesión 3:** Implementación del PWM y Display 7-segmentos[cite: 153].
- [ ] [cite_start]**Sesión 4:** Integración final y competición[cite: 154].

## ⚙️ Configuración y Pruebas (Sesión 1)

Para validar la lógica sin el robot físico completo, se utilizan los **Switches (Pmod SWT)** y **LEDs RGB** de la placa Cora Z7:

1.  [cite_start]**Simulación de Sensores:** Los switches emulan la detección de obstáculos (True/False)[cite: 176].
2.  **Visualización de Estados:**
    * **Verde:** Navegación normal.
    * [cite_start]**Rojo:** Salida alcanzada (4 de 5 sensores inferiores activos)[cite: 215, 216].

---
