with UART; use UART;
with Ada.Real_Time; use ada.real_time;
with gpio; use gpio;
with System.Multiprocessors;use System.Multiprocessors;
with Ada.Text_IO; use Ada.Text_IO; -- Para Put_Line si UART no es suficiente

procedure Demo is

   izq, drcha : boolean;
   distancia, d_min, d_max : float;
   n_inf, n_infL : integer;
   
   -- Definimos estados ampliados
   type estado is (Espera_Inicio, Avanzar, Girar_Izq, Girar_Der, Corregir_Izq, Corregir_Der, Meta, Pausa_Meta);
   eActual : estado;
   
   -- Variables para lógica de botones
   Btn_Start_Pressed : Boolean := False;
   Btn_Reset_Pressed : Boolean := False;

begin
   -- Inicialización Hardware
   InitUART(nUart => 0);
   Init; -- Inicializa GPIOs
   
   -- Configuración Inicial
   eActual := Espera_Inicio;
   GPIO.Contador_ctrl.Set_EN(0); -- Reset contador
   
   -- Parámetros calibración (Ajustar en el lab)
   d_min := 4.0;  -- cm. Si menor, está muy cerca pared derecha.
   d_max := 20.0; -- cm. Si mayor, se aleja de pared derecha.
   n_infL := 4;   -- Meta detectada si 4 o 5 sensores negros.

   loop
      -- 1. LECTURA DE SENSORES
      izq := GPIO.Datos_Sensores.Get_S_I;
      drcha := GPIO.Datos_Sensores.Get_S_D;
      n_inf := Datos_Sensores.Get_Infrarrojos;
      distancia := Datos_Sensores.Get_Distancia;
      
      -- Leemos botones físicos
      Btn_Start_Pressed := GPIO.ReadButton0; 
      Btn_Reset_Pressed := GPIO.ReadButton1;

      -- 2. MÁQUINA DE ESTADOS
      case eActual is
         
         -- ESTADO 0: ESPERANDO ARRANQUE
         when Espera_Inicio =>
            GPIO.Para; -- Motores parados
            GPIO.EnciendeRGB(blue, blue); -- Indicador visual: Listo
            GPIO.Contador_ctrl.Set_EN(0); -- Contador a 0
            
            if Btn_Start_Pressed then
               -- Esperar a que suelte el botón (debounce simple)
               delay 0.5; 
               eActual := Avanzar;
               GPIO.Contador_ctrl.Set_EN(1); -- Iniciar Cronómetro
            end if;

         -- NAVEGACIÓN
         when Avanzar =>
            GPIO.Avanza;
            GPIO.EnciendeRGB(green, green);
            
            -- Prioridad 1: Meta
            if n_inf >= n_infL then
               eActual := Meta;
            
            -- Prioridad 2: Choque frontal inminente (IRF)
            elsif izq or drcha then
               eActual := Girar_Izq; -- Giramos a izq si hay obstáculo delante
               
            -- Prioridad 3: Pared lateral (Ultrasonidos)
            elsif distancia < d_min and distancia > 0.1 then 
               -- Muy cerca de la pared derecha -> Corregir a Izquierda
               eActual := Corregir_Izq;
            elsif distancia > d_max then
               -- Muy lejos de la pared (o hueco) -> Acercarse a derecha
               -- OJO: Si distancia es enorme (>50cm) puede ser esquina abierta.
               -- Algoritmo mano derecha: Si pierdo la pared, debo girar a la derecha para buscarla.
               eActual := Corregir_Der;
            else
               -- Distancia correcta, seguimos recto
               eActual := Avanzar;
            end if;

         when Girar_Izq =>
            GPIO.Girar_Izq;
            GPIO.EnciendeRGB(blue, off);
            -- Giramos hasta que se despeje el frente
            if not (izq or drcha) then
               -- Añadir pequeño delay o histéresis si necesario
               eActual := Avanzar;
            end if;
            
         when Girar_Der =>
            -- Esto ocurre típicamente si perdemos la pared ("esquina convexa")
            GPIO.Girar_Der;
            GPIO.EnciendeRGB(off, blue);
            -- Giramos hasta recuperar pared (distancia < d_max) o por tiempo
            if distancia < d_max then
                eActual := Avanzar;
            end if;
            
         when Corregir_Izq =>
            GPIO.Corregir_Izq;
            GPIO.EnciendeRGB(violet, off);
            if distancia >= d_min + 2.0 then -- Histéresis de 2cm
               eActual := Avanzar;
            end if;

         when Corregir_Der =>
            GPIO.Corregir_Der;
            GPIO.EnciendeRGB(off, violet);
            if distancia <= d_max - 2.0 then
               eActual := Avanzar;
            end if;

         -- META
         when Meta =>
            GPIO.Para;
            GPIO.EnciendeRGB(red, red);
            GPIO.Contador_ctrl.Set_EN(2); -- Parar contador (hold)
            eActual := Pausa_Meta;
            
         when Pausa_Meta =>
            GPIO.Para;
            -- Esperar botón de Rearme (Reset)
            if Btn_Reset_Pressed then
               delay 0.5;
               eActual := Espera_Inicio;
            end if;

      end case;
      
      -- DEBUG POR CONSOLA (Opcional, ralentiza si es muy frecuente)
      -- Put("Estado: " & estado'Image(eActual));
      -- Put_Line(" Dist: " & Float'Image(distancia));
      
      delay 0.05; -- Ciclo de control principal (20Hz aprox)
      
   end loop;
   
   delay until Ada.Real_Time.Time_Last;
end Demo;