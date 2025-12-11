with UART; use UART;
with Ada.Real_Time; use ada.real_time;
with gpio; use gpio;
with System.Multiprocessors;use System.Multiprocessors;

procedure Demo is

   izq, drcha : boolean;
   distancia, d_min, d_max : float;
   n_inf, n_infL : integer; 
   
   -- DEFICI�N DE LOS ESTADOS DE NUESTRA M�QUINA (a completar)
   type estado is (Inicio, Avanzar, Girar_Izq, Girar_Der, Corregir_Izq, Corregir_Der, Meta);
   eActual : estado;
   -- eActual : estado; -- Variable que indica el estado actual
   
   procedure Check_SMP is
   begin
      Put_Line("Cores disponibles: " & 
                 CPU_Range'Image(System.Multiprocessors.Number_Of_CPUs));
   
      if System.Multiprocessors.Number_Of_CPUs >= 2 then
         Put_Line("Sistema multicore detectado correctamente");
      else
         Put_Line("ADVERTENCIA: Solo se detect� 1 core");
      end if;
   end Check_SMP;
   
begin
    -- UART0 => Cora board
   InitUART(nUart => 0);
   
   -- Check_SMP;
   
   -- Procedure para inicializar los puertos GPIO de todos los dispositivos.
   -- Importante. NO BORRAR
   Init;

   eActual := Inicio;
   
   -- Umbrales de distancia (ajustar según pruebas reales)
   d_min := 10.0; 
   d_max := 20.0;
   
   -- Mínimo de sensores IR para considerar "Meta" (4 o 5)
   n_infL := 4;
   

   --eActual := Inicio;
   --d_min := ; --  Distancia m�nima del ultrasonidos hasta la pared
   --d_max := ;Distancia m�xima del ultrasonidos hasta la pared
   --n_infL := ; -- N�mero de infrarrojos inferiores m�nimos (en alto) para detectar meta

   loop
      -- LECTURA DE SENSORES (a completar)
      
      -- Valor del sensor frontal izquierdo (IRF1)
      izq :=  GPIO.Datos_Sensores.Get_S_I;
      -- Valor del sensor frontal derecho (IRF2)
      drcha := GPIO.Datos_Sensores.Get_S_D;  
      
      
      -- N� de Infrarrojos inferiores detectados (IRI)
      -- n_inf :=
      n_inf := Datos_Sensores.Get_Infrarrojos;
      
      -- Valor de la distancia medida por el ultrasonidos (a completar - Sesi�n 2)
      -- distancia := 
      distancia := Datos_Sensores.Get_Distancia;
      
      -- IMPRIMIR LOS VALORES DE LOS SENSORES (a completar)
      
      Put("IRF_I: " & Boolean'Image(izq));
      Put(" | IRF_D: " & Boolean'Image(drcha));
      Put(" | IRI_Activos: " & Integer'Image(n_inf));
      -- Mostramos la distancia con 2 decimales aprox (Float'Image suele sacar notación científica, 
      -- para simplificar aquí usamos la conversión estándar)
      Put_Line(" | Distancia: " & Float'Image(distancia) & " cm");
      
      -- IMPLEMENTACI�N DE LA M�QUINA DE ESTADOS (a completar)
      
      case eActual is
         when Inicio =>
            eActual := Avanzar;

         when Avanzar =>
            -- Si detectamos la meta (4 o más sensores de suelo activos)
            if n_inf >= n_infL then
               eActual := Meta;
            
            -- Si hay obstáculo frontal (IRF)
            elsif izq or drcha then
               eActual := Girar_Izq; 

            -- Lógica con Ultrasonidos (Control de pared derecha)
            -- Si estamos muy cerca (< 10cm) -> Corregir a la izquierda
            elsif distancia < d_min and distancia > 0.0 then -- >0 para evitar lecturas erróneas
               eActual := Corregir_Izq;
               
            -- Si estamos muy lejos (> 20cm) -> Corregir a la derecha (acercarse)
            -- Nota: Si es muy grande (> 50cm) podría ser una esquina/hueco
            elsif distancia > d_max then
               eActual := Corregir_Der;
               
            else
               eActual := Avanzar;
            end if;

         when Girar_Izq =>
            -- Giramos hasta que no haya obstáculo
            if not (izq or drcha) then
               eActual := Avanzar;
            end if;
            
         when Corregir_Izq =>
            -- Volvemos a avanzar cuando la distancia sea segura
            if distancia >= d_min then
               eActual := Avanzar;
            end if;

         when Corregir_Der =>
            -- Volvemos a avanzar cuando estemos cerca de nuevo
            if distancia <= d_max then
               eActual := Avanzar;
            end if;

         when Meta =>
            null; -- Fin del trayecto

         when others => 
            eActual := Avanzar;
      end case;
      
      -- ACTUADORES (LEDS por ahora)
      case eActual is
         when Avanzar => 
            EnciendeRGB(green, green);
         when Girar_Izq | Girar_Der => 
            EnciendeRGB(blue, off); -- Indicar giro
         when Corregir_Izq | Corregir_Der =>
            EnciendeRGB(violet, violet); -- Indicar corrección suave
         when Meta => 
            EnciendeRGB(red, red);
         when others => 
            EnciendeRGB(off, off);
      end case;

      -- identificaci�n del estado
      --  case eActual is
      --     when Estado1 =>
      --        if condicion then eActual := estadoX; end if;
      --     when Estado2 =>
      --        if condicion then eActual := estadoY;end if;
      --        ...
      --     when others => null;
      --  end case;
      --  
      --  
      --  
      --  -- qu� hacer en cada estado
      --  case eActual is
      --     when Estado1 => Put_Line("M�quina en estado 1");
      --     when Estado2 => Put_Line("M�quina en estado 2");
      --     ...
      --     when others => Put_Line("Estado inconsistente");
      --  end case;
      
      delay 0.25;
      
   end loop;
   
   
   -- No borrar la siguiente l�nea
   delay until Ada.Real_Time.Time_Last;
   
end Demo;

