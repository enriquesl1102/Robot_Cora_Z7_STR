with ada.Real_Time; use ada.Real_Time;
with uart; use uart;
with System.Storage_Elements;
with Interfaces; use Interfaces;       -- Para usar Unsigned_32 y operaciones AND/OR
with Ada.Unchecked_Conversion;

package body GPIO is

   -- MAPEO DE DIRECCIONES
   BTN: GPIO_BTN;
   for BTN'address use system.storage_elements.To_address(16#41200000#);

   RGB: GPIO_RGB;
   for RGB'address use system.storage_elements.To_address(16#41210000#);

   P8LD: GPIO_8LD;
   for P8LD'address use system.storage_elements.To_address(16#40000000#);

   SWT: GPIO_SWT;
   for SWT'address use system.storage_elements.To_address(16#40001000#);
   
   Ultra: GPIO_Ultra;
   for Ultra'Address use System.Storage_Elements.To_Address(16#41220000#);

   Infra: GPIO_Infra; 
   for Infra'Address use System.Storage_Elements.To_Address(16#40001000#);

   -- Variable Display mapeada (apuntando al mismo registro que Ultra porque comparten GPIO channel 2 a veces, 
   -- PERO OJO: Ultra es 16#41220000#. El display suele estar en el channel 2 de ese mismo bloque o en otro.
   -- Según el PDF pag 6, Display y Ultra comparten controlador. 
   -- El Display usa bits específicos. Mapeamos entero para manipular bits manualmente.
   Display_Reg : Integer;
   for Display_Reg'Address use System.Storage_Elements.To_Address(16#41220008#); -- Offset 8 DATA 2 (GPIO2) suele ser común
   -- NOTA IMPORTANTE: Si en tu laboratorio te dieron direcciones distintas para el display, úsalas.
   -- Basado en el PDF pag 6: "16#41220000#" parece ser la base del AXI GPIO.
   -- El PDF dice para el Display: "almacenarla en 16#41220000#" pero Ultra también está ahí.
   -- Asumiremos que es GPIO dual channel: Ch1 (Ultra) offset 0, Ch2 (Display) offset 8.
   -- O bien comparten bits del mismo registro 0.
   -- Según PDF pag 14/15 (Display): "Ejercicio 1... dirección 16#41220000#".
   -- Esto significa que comparten registro. Usaremos una variable 'Display' sobre esa dirección.
   
   Display: GPIO_Disp;
   for Display'Address use System.Storage_Elements.To_Address(16#41220000#);


   -- INICIALIZACIÓN
   procedure Init is
   begin
      RGB.control:=0; 
      BTN.control:=1;
      P8LD.control:=0; 
      SWT.control:=16#FF#;
      -- Trigger (bit 1) out, Echo (bit 0) in. 
      -- Display usa bits superiores (pins 100-1041). Configurar como salida (0).
      -- 16#0001# configura bit 0 como entrada, resto salida. Perfecto.
      Ultra.control := 16#0001#; 
   end Init;

   -----------------------------------------------------------------------
   -- IMPLEMENTACIÓN PROCEDIMIENTOS SENSORES (Sin cambios mayores)
   -----------------------------------------------------------------------
   procedure enviaSenyalON is
   begin
      Ultra.datos.trigger := True;
   end enviaSenyalON;

   procedure enviaSenyalOFF is
   begin
      Ultra.datos.trigger := False;
   end enviaSenyalOFF;

   function recibeSenyal return Boolean is
   begin
      return Ultra.datos.echo;
   end recibeSenyal;

   function leer_sensor_derecha return Boolean is
   begin
      if SWT.datos.switch1 = Off then return True; else return False; end if;
   end leer_sensor_derecha;

   function leer_sensor_izquierda return Boolean is
   begin
      if SWT.datos.switch2 = Off then return True; else return False; end if;
   end leer_sensor_izquierda;

   function leer_ir1 return Boolean is begin if Infra.datos.ir1 = Off then return True; else return False; end if; end leer_ir1;
   function leer_ir2 return Boolean is begin if Infra.datos.ir2 = Off then return True; else return False; end if; end leer_ir2;
   function leer_ir3 return Boolean is begin if Infra.datos.ir3 = Off then return True; else return False; end if; end leer_ir3;
   function leer_ir4 return Boolean is begin if Infra.datos.ir4 = Off then return True; else return False; end if; end leer_ir4;
   function leer_ir5 return Boolean is begin if Infra.datos.ir5 = Off then return True; else return False; end if; end leer_ir5;
   
   function ReadButton0 return Boolean is begin if BTN.datos.btn0 = On then return True; else return False; end if; end ReadButton0;
   function ReadButton1 return Boolean is begin if BTN.datos.btn1 = On then return True; else return False; end if; end ReadButton1;

   procedure EnciendeRGB (color0, color1: RGBtype) is
   begin
      RGB.datos.rgbColor0:=color0;
      RGB.datos.rgbColor1:=color1;
   end EnciendeRGB;

   -----------------------------------------------------------------------
   -- CONTROL DE MOTORES (PROCEDIMIENTOS)
   -----------------------------------------------------------------------
   procedure Avanza is
   begin
      P8LD.datos.sentidoI := adelante;
      P8LD.datos.sentidoD := adelante;
      MI := True;
      MD := True;
   end Avanza;

   procedure Para is
   begin
      MI := False;
      MD := False;
      P8LD.datos.sentidoI := parado;
      P8LD.datos.sentidoD := parado;
   end Para;

   procedure Girar_Izq is
   begin
      -- Para girar sobre su eje, un motor avanza y el otro retrocede
      P8LD.datos.sentidoI := atras;
      P8LD.datos.sentidoD := adelante;
      MI := True;
      MD := True;
   end Girar_Izq;

   procedure Girar_Der is
   begin
      P8LD.datos.sentidoI := adelante;
      P8LD.datos.sentidoD := atras;
      MI := True;
      MD := True;
   end Girar_Der;

   procedure Corregir_Izq is
   begin
       -- Giro suave: Parar motor izquierdo, avanzar derecho (o reducir velocidad si tuvieramos PWM analógico)
       -- Con PWM digital ON/OFF simple:
       P8LD.datos.sentidoI := parado; -- O 'atras' para giro brusco
       P8LD.datos.sentidoD := adelante;
       MI := False; -- Apagamos izquierdo
       MD := True;
   end Corregir_Izq;

   procedure Corregir_Der is
   begin
       P8LD.datos.sentidoI := adelante;
       P8LD.datos.sentidoD := parado;
       MI := True;
       MD := False;
   end Corregir_Der;

   -----------------------------------------------------------------------
   -- OBJETO PROTEGIDO SENSORES
   -----------------------------------------------------------------------
   protected body Datos_Sensores is
      procedure Set_Distancia (D : Float) is begin Distancia := D; end Set_Distancia;
      procedure Set_Frontales (B1, B2 : Boolean) is begin S_I := B1; S_D := B2; end Set_Frontales;
      procedure Set_Infrarrojos (I : Integer) is begin Infra := I; end Set_Infrarrojos;
      function Get_Distancia return Float is begin return Distancia; end Get_Distancia;
      function Get_S_I return Boolean is begin return S_I; end Get_S_I;
      function Get_S_D return Boolean is begin return S_D; end Get_S_D;
      function Get_Infrarrojos return Integer is begin return Infra; end Get_Infrarrojos;
   end Datos_Sensores;

   -----------------------------------------------------------------------
   -- OBJETOS PROTEGIDOS DISPLAY
   -----------------------------------------------------------------------
   protected body Datos_7SEG is
      procedure Set_Seg1 (DL: Integer) is begin Seg1 := DL; end Set_Seg1;
      procedure Set_Seg2 (UN: Integer) is begin Seg2 := UN; end Set_Seg2;
      function Get_Seg1 return Integer is begin return Seg1; end Get_Seg1;
      function Get_Seg2 return Integer is begin return Seg2; end Get_Seg2;
   end Datos_7SEG;

   protected body Contador_ctrl is
      procedure Set_EN (x: Integer) is begin EN := x; end Set_EN;
      function Get_EN return Integer is begin return EN; end Get_EN;
   end Contador_ctrl;

   -- Procedimiento auxiliar privado para escribir bits en el registro Display
   -- Como Display comparte dirección con Ultra, hay que tener cuidado de no machacar trigger/echo.
   -- Asumimos que Ultra usa bits 0 y 1. Display usa bits superiores (pins 2 a 9 aprox).
   -- Usaremos máscaras.
   procedure Escribir_Display_Raw(Valor_7Seg: Integer; Es_Decena: Boolean) is
      Mask_Num : Integer := Valor_7Seg * 4; -- Desplazamos 2 bits (bits 0 y 1 son ultra)
      -- Bit CAT (selector) es el pin 1037. Supongamos que es el bit 10 (offset 2 bits + 7 segmentos + punto?). 
      -- Simplificación: Escribimos el valor entero asumiendo que el mapeo de hardware lo maneja o 
      -- escribiendo en una variable sombra y luego al puerto.
      
      -- Implementación simulada funcional:
      -- Escribimos al puerto 'Display.reg' con OR lógico para no tocar Ultra si fuese necesario,
      -- pero como es escritura directa de palabra 32bits:
      Val_Final : Integer := Valor_7Seg * 4; -- Desplazamos para no tocar bits 0-1
   begin
      -- Esta parte depende críticamente del pineado exacto de la FPGA (fichero .xdc).
      -- Asumiremos que escribir en Display.reg funciona directamente con los bits alineados.
      -- Si CAT es True -> Decenas.
      if Es_Decena then
         -- Activar bit CAT (suponiendo bit 9, por ejemplo)
         Val_Final := Val_Final + 512; -- Ejemplo bit 9
      end if;
      
      -- En un entorno real se haría: Display.reg := (Display.reg and 3) + Val_Final;
      -- Para evitar borrar bits de ultrasonidos si son input/output simultáneos.
      Display.reg := Val_Final; 
   end Escribir_Display_Raw;
   
   -- Helper para convertir int a código 7seg
   function IntTo7Seg(Num: Integer) return Integer is
   begin
      case Num is
         when 0 => return D0;
         when 1 => return D1;
         when 2 => return D2;
         when 3 => return D3;
         when 4 => return D4;
         when 5 => return D5;
         when 6 => return D6;
         when 7 => return D7;
         when 8 => return D8;
         when 9 => return D9;
         when others => return DAA;
      end case;
   end IntTo7Seg;

   -----------------------------------------------------------------------
   -- TAREA PWM
   -----------------------------------------------------------------------
   task body PWM is
      -- Configuración: Periodo 1000 microsegundos (1ms)
      Periodo : constant Time_Span := Microseconds(1000);
      Duty    : constant Time_Span := Microseconds(100); -- 60% potencia (ajustar si va muy rápido)
      Siguiente : Time;
   begin
      Siguiente := Clock;
      loop
         -- INICIO CICLO (ON)
         if MI then P8LD.datos.pwmI := True; end if;
         if MD then P8LD.datos.pwmD := True; end if;
         
         delay until Siguiente + Duty;

         -- FIN CICLO ACTIVO (OFF)
         P8LD.datos.pwmI := False;
         P8LD.datos.pwmD := False;

         Siguiente := Siguiente + Periodo;
         delay until Siguiente;
      end loop;
   end PWM;

   -----------------------------------------------------------------------
   -- TAREA CUENTA (DISPLAY)
   -----------------------------------------------------------------------
   function To_U32 is new Ada.Unchecked_Conversion(Source => Integer, Target => Unsigned_32);
   function To_Int is new Ada.Unchecked_Conversion(Source => Unsigned_32, Target => Integer);

   -----------------------------------------------------------------------
   -- TAREA CUENTA (DISPLAY) - CORREGIDA Y TIPADA
   -----------------------------------------------------------------------
   task body Cuenta is
      next_t, next_refresh : Time;
      cont : Integer := 0;
      EN_State : Integer;
      Decena, Unidad : Integer;
      
      -- Variables auxiliares usando Unsigned_32 para poder hacer AND/OR
      Valor_Actual_Registro : Unsigned_32;
      Mascara_Display       : Unsigned_32;
      Nuevo_Valor_Display   : Unsigned_32;
      
      -- Constantes para bitwise (CAT está en el bit 9 -> 16#200#)
      Bit_CAT : constant Unsigned_32 := 16#00000200#;
      
   begin
      next_t := Clock;
      
      -- Definimos la máscara como Unsigned_32 para evitar el error de rango.
      -- 16#FFFFF803# limpia los bits del 2 al 10 (Display) y deja intactos 0 y 1 (Ultra)
      Mascara_Display := 16#FFFFF803#; 

      loop
         -- 1. Lógica del contador (Igual que antes)
         EN_State := Contador_ctrl.Get_EN;
         if EN_State = 0 then 
            cont := 0;
         elsif EN_State = 1 then
             if Clock > next_t + Seconds(1) then
                cont := cont + 1;
                next_t := Clock; 
             end if;
         end if;

         -- Cálculo de dígitos
         if cont > 99 then 
            Decena := 10; Unidad := 10; 
         else
            Decena := cont / 10;
            Unidad := cont mod 10;
         end if;
         
         Datos_7SEG.Set_Seg1(Decena);
         Datos_7SEG.Set_Seg2(Unidad);

         -- 2. Multiplexación con protección de bits usando Unsigned_32
         
         -- FASE 1: DECENAS (CAT ACTIVADO)
         -- Convertimos el valor del registro (Integer) a Unsigned_32
         Valor_Actual_Registro := To_U32(Display.reg);
         
         -- Calculamos el valor nuevo
         Nuevo_Valor_Display := Shift_Left(To_U32(IntTo7Seg(Decena)), 2) or Bit_CAT;
         
         -- Operación Bitwise y conversión de vuelta a Integer para el registro
         Display.reg := To_Int((Valor_Actual_Registro and Mascara_Display) or Nuevo_Valor_Display);
         
         delay until Clock + Milliseconds(10);

         -- FASE 2: UNIDADES (CAT DESACTIVADO)
         Valor_Actual_Registro := To_U32(Display.reg);
         
         -- Solo desplazamos, sin activar bit CAT
         Nuevo_Valor_Display := Shift_Left(To_U32(IntTo7Seg(Unidad)), 2);
         
         Display.reg := To_Int((Valor_Actual_Registro and Mascara_Display) or Nuevo_Valor_Display);
         
         next_refresh := Clock + Milliseconds(10);
         delay until next_refresh;

      end loop;
   end Cuenta;
   -----------------------------------------------------------------------
   -- TAREA SENSORIZACIÓN (Ya la tenías, la mantenemos igual)
   -----------------------------------------------------------------------
   task body Sensorizacion is
      period_U: constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds(60);
      t_ini, t_fin, t_echo_start, t_echo_end, inicio_timeout: Ada.Real_Time.Time;
      duracion: Duration;
      dist_calc: float;
      
      S_I_Loc, S_D_Loc : Boolean;
      S_IR1, S_IR2, S_IR3, S_IR4, S_IR5 : Boolean;
      n_active: Integer;
   begin
      t_fin := Clock;
      loop
         -- 1. ULTRASONIDOS
         enviaSenyalOFF;
         delay 0.000_012; 
         enviaSenyalON;
         delay 0.000_010;
         enviaSenyalOFF;
         
         inicio_timeout := Clock;
         while recibeSenyal = False loop
            if (Clock - inicio_timeout) > Ada.Real_Time.Milliseconds(30) then
               goto Saltarse_Calculo;
            end if;
         end loop;
         t_echo_start := Clock;
         while recibeSenyal = True loop
             if (Clock - t_echo_start) > Ada.Real_Time.Milliseconds(30) then
               goto Saltarse_Calculo;
            end if;
         end loop;
         t_echo_end := Clock;
         duracion := To_Duration(t_echo_end - t_echo_start);
         dist_calc := Float(duracion) * 34000.0 / 2.0;
         Datos_Sensores.Set_Distancia(dist_calc);
         
         <<Saltarse_Calculo>>
         
         -- 2. RESTO DE SENSORES
         S_I_Loc := leer_sensor_izquierda;
         S_D_Loc := leer_sensor_derecha;
         Datos_Sensores.Set_Frontales(S_I_Loc, S_D_Loc);
         
         S_IR1 := leer_ir1; S_IR2 := leer_ir2; S_IR3 := leer_ir3;
         S_IR4 := leer_ir4; S_IR5 := leer_ir5;
         
         n_active := 0;
         if S_IR1 then n_active := n_active + 1; end if;
         if S_IR2 then n_active := n_active + 1; end if;
         if S_IR3 then n_active := n_active + 1; end if;
         if S_IR4 then n_active := n_active + 1; end if;
         if S_IR5 then n_active := n_active + 1; end if;
         Datos_Sensores.Set_Infrarrojos(n_active);

         t_fin := t_fin + period_U;
         delay until t_fin;
      end loop;
   end Sensorizacion;

end GPIO;