with ada.Real_Time; use ada.Real_Time;
with uart;use uart;

package body GPIO is

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


   procedure Init is
   begin
      RGB.control:=0; --out
      BTN.control:=1; --in
      P8LD.control:=0; --out
      SWT.control:=16#FF#; --todo in, infrarrojos obstaculos y siguelineas
      Ultra.control := 16#0001#; --Trigger out (IO27), echo in (IO26) D = 1101. 
   end Init;



   -- sensores funcionan con l�gica negada
   function leer_sensor_derecha return Boolean is
   begin

      if SWT.datos.switch1 = Off then
         return True;
      else
         return False;
      end if;
   end leer_sensor_derecha;

   function leer_sensor_izquierda return Boolean is
   begin
      if SWT.datos.switch2 = Off then
         return True;
      else
         return False;
      end if;
   end leer_sensor_izquierda;
   
   
   -- Completar 
   -- sensores funcionan con l�gica negada

   function leer_ir1 return Boolean is
   begin
      if Infra.datos.ir1 = Off then return True; else return False; end if;
   end leer_ir1;
   
   function leer_ir2 return Boolean is
   begin
      if Infra.datos.ir2 = Off then return True; else return False; end if;
   end leer_ir2;

   function leer_ir3 return Boolean is
   begin
      if Infra.datos.ir3 = Off then return True; else return False; end if;
   end leer_ir3;

   function leer_ir4 return Boolean is
   begin
      if Infra.datos.ir4 = Off then return True; else return False; end if;
   end leer_ir4;

   function leer_ir5 return Boolean is
   begin
      if Infra.datos.ir5 = Off then return True; else return False; end if;
   end leer_ir5;
   
   
   function ReadButton0 return Boolean is 
   begin 
      if BTN.datos.btn0 = On then 
         return True;
      else
         return False;
      end if;
   end ReadButton0;
   
   function ReadButton1 return Boolean is 
   begin 
      if BTN.datos.btn1 = On then 
         return True;
      else
         return False;
      end if;
   end ReadButton1;
   
   procedure EnciendeRGB (color0, color1: RGBtype) is
   begin
      RGB.datos.rgbColor0:=color0;
      RGB.datos.rgbColor1:=color1;

   end EnciendeRGB;

   
   protected body Datos_Sensores is
   
      procedure Set_Distancia (D : Float) is
      begin
         Distancia := D;
      end Set_Distancia;
      
      procedure Set_Frontales (B1, B2 : Boolean) is
      begin
         S_I := B1;
         S_D := B2;
      end Set_Frontales;

      procedure Set_Infrarrojos (I : Integer) is
      begin
         Infra := I;
      end Set_Infrarrojos;
      
      function Get_Distancia return Float is
      begin
         return Distancia;
      end Get_Distancia;
      
      function Get_S_I return Boolean is
      begin
         return S_I;
      end Get_S_I;
      
      function Get_S_D return Boolean is 
      begin
         return S_D;
      end Get_S_D;
      
      function Get_Infrarrojos return Integer is
      begin
         return Infra;
      end Get_Infrarrojos;
      
   end Datos_Sensores;
   
 

   task body Sensorizacion is
      period_U: constant Ada.Real_Time.Time_Span := Ada.Real_Time.Milliseconds(300); -- ultrasonidos
      t_ini, t_fin, t_echo_start, t_echo_end, inicio:  Ada.Real_Time.Time := Ada.Real_Time.Clock;
      duracion: Duration;
      dist_calc: float;
      S_I,S_D, S_IR1, S_IR2, S_IR3, S_IR4, S_IR5 : Boolean; 
      n_active: Integer;

   begin

      bucle_ext: loop
             
         -- Ultrasonidos (a completar - Sesi�n 2
         
         t_fin:=Clock;

         Ultra.datos.trigger := True;
         -- Retardo pequeño (mínimo 10us, aquí usamos un delay relativo pequeño o bucle)
         delay 0.000_015; 
         Ultra.datos.trigger := False;
         
         -- Esperar inicio del Echo (Flanco de subida) con Timeout
         t_ini := Clock;
         while Ultra.datos.echo = False loop
            if (Clock - t_ini) > Ada.Real_Time.Milliseconds(30) then
               exit; -- Timeout si no responde
            end if;
         end loop;
         t_echo_start := Clock;
         
         -- Esperar fin del Echo (Flanco de bajada)
         while Ultra.datos.echo = True loop
             if (Clock - t_echo_start) > Ada.Real_Time.Milliseconds(30) then
               exit; -- Timeout (distancia máxima excedida)
            end if;
         end loop;
         t_echo_end := Clock;
         
         -- Calcular distancia: (Tiempo * Velocidad Sonido) / 2
         -- Velocidad sonido ~340 m/s = 34000 cm/s
         duracion := To_Duration(t_echo_end - t_echo_start);
         dist_calc := Float(duracion) * 34000.0 / 2.0;
         
         -- Guardar en objeto protegido
         Datos_Sensores.Set_Distancia(dist_calc);



         -------------
         --Infrarrojos frontales IRF
         S_I := leer_sensor_izquierda;
         S_D := leer_sensor_derecha;
         Datos_Sensores.Set_Frontales(S_I,S_D);
         
         --Infrarrojos inferiores IRI (a completar)
         S_IR1 := leer_ir1;
         S_IR2 := leer_ir2;
         S_IR3 := leer_ir3;
         S_IR4 := leer_ir4;
         S_IR5 := leer_ir5;
         
         -- Contar cuántos están activos
         n_active := 0;
         if S_IR1 then n_active := n_active + 1; end if;
         if S_IR2 then n_active := n_active + 1; end if;
         if S_IR3 then n_active := n_active + 1; end if;
         if S_IR4 then n_active := n_active + 1; end if;
         if S_IR5 then n_active := n_active + 1; end if;
         
         -- Guardar en objeto protegido
         Datos_Sensores.Set_Infrarrojos(n_active);


         delay until t_fin + period_U;

      end loop bucle_ext;
   end Sensorizacion;


   
end GPIO;
