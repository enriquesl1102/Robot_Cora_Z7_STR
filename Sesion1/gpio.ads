with System.Storage_Elements;
with System.Multiprocessors; use System.Multiprocessors;
with Ada.Real_Time; use Ada.Real_Time;

package GPIO is

   -- Variables globales para control PWM (MI = Motor Izquierdo, MD = Motor Derecho)
   MI, MD: boolean := False; 

   -- Definición de tipos básicos de tamaño fijo
   type ButtonState is (Off, On);
   for ButtonState use (Off => 2#0#, On => 2#1#);
   for ButtonState'Size use 1;

   -- LEDs RGB (3 bits)
   type RGBtype is (off, red, green, blue, violet);
   for RGBtype use (off=>2#000#, red=>2#001#, green=>2#010#, blue=>2#100#, violet=>2#101#);
   for RGBtype'Size use 3;

   -- Sentido Motor (2 bits)
   type sentido is (parado, atras, adelante);
   for sentido use (parado=>2#00#, atras=>2#01#, adelante=>2#10#);
   for sentido'Size use 2;

   ------------------------------------------------------------------
   -- DEFINICIÓN DE REGISTROS (Mapeo de Hardware)
   ------------------------------------------------------------------

   -- 1. BOTONES
   type Ctrl_BTN is record
      btn0 : ButtonState;
      btn1 : ButtonState;
   end record;
   for Ctrl_BTN use record
      btn0 at 0 range 0..0;
      btn1 at 0 range 1..1;
   end record;

   type GPIO_BTN is record
      datos : Ctrl_BTN;
      control : Integer;
   end record;

   -- 2. LEDS RGB
   type Ctrl_RGB is record
      rgbColor0:RGBtype;
      rgbColor1:RGBtype;
   end record;
   for Ctrl_RGB use record
      rgbColor0 at 0 range 0..2;
      rgbColor1 at 0 range 3..5;
   end record;

   type GPIO_RGB is record
      datos:Ctrl_RGB;
      control: integer;
   end record;

   -- 3. MOTORES (P8LD)
   type Ctrl_Motor is record
      pwmI:boolean;
      sentidoI:sentido;
      pwmD:boolean;
      sentidoD:sentido;
   end record;
   for Ctrl_Motor use record
      pwmI at 0 range 0..0;
      sentidoI at 0 range 1..2;
      pwmD at 0 range 4..4;
      sentidoD at 0 range 5..6;
   end record;

   type GPIO_8LD is record
      datos:Ctrl_Motor;
      control: integer;
   end record;

   -- 4. SWITCHES
   type Ctrl_Switch is record
      switch1 : ButtonState;
      switch2 : ButtonState;
   end record;
   for Ctrl_Switch use record
      switch1 at 0 range 5..5;
      switch2 at 0 range 6..6;
   end record;

   type GPIO_SWT is record
      datos : Ctrl_Switch;
      control : Integer;
   end record;

   -- 5. INFRARROJOS INFERIORES (IRI)
   type Ctrl_Infra is record
      ir1 : ButtonState;
      ir2 : ButtonState;
      ir3 : ButtonState;
      ir4 : ButtonState;
      ir5 : ButtonState;
   end record;
   for Ctrl_Infra use record
      ir1 at 0 range 0..0;
      ir2 at 0 range 1..1;
      ir3 at 0 range 2..2;
      ir4 at 0 range 3..3;
      ir5 at 0 range 4..4;
   end record;

   type GPIO_Infra is record
      datos : Ctrl_Infra;
      control : Integer;
   end record;

   -- 6. ULTRASONIDOS
   type Ctrl_Ultra is record
      trigger : Boolean; -- out
      echo : Boolean;    -- in
   end record;
   for Ctrl_Ultra use record
      trigger at 0 range 1..1;
      echo at 0 range 0..0;
   end record;

   type GPIO_Ultra is record
      datos : Ctrl_Ultra;
      control : Integer;
   end record;

   -- 7. DISPLAY 7 SEGMENTOS (Corrección del error de compilación)
   -- En lugar de dividirlo en bits pequeños que dan error con Integer,
   -- definimos el registro completo como un entero de 32 bits.
   type GPIO_Disp is record
       Reg     : Integer; 
       Control : Integer;
   end record;
   for GPIO_Disp use record
       Reg     at 0 range 0..31; -- Ocupa los 32 bits completos
       Control at 4 range 0..31;
   end record;

   -- Constantes para números en el Display (Hexadecimal)
   -- CORRECCIÓN EN GPIO.ADS
   D0: constant Integer := 2#00111111#; -- Corregido: Enciende segmentos A-F
   D1: constant Integer := 2#00000110#;
   D2: constant Integer := 2#01011011#;
   D3: constant Integer := 2#01001111#;
   D4: constant Integer := 2#01100110#;
   D5: constant Integer := 2#01101101#;
   D6: constant Integer := 2#01111101#;
   D7: constant Integer := 2#00000111#;
   D8: constant Integer := 2#01111111#;
   D9: constant Integer := 2#01100111#;
   DAA: constant Integer := 2#01110111#; -- Letra 'A'

   ----------------------------------------------------------------------
   -- OBJETOS PROTEGIDOS
   ----------------------------------------------------------------------
   protected Datos_Sensores is
      procedure Set_Distancia (D : Float);
      procedure Set_Frontales (B1, B2 : Boolean);
      procedure Set_Infrarrojos (I : Integer);
      function Get_Distancia return Float;
      function Get_S_I return Boolean;
      function Get_S_D return Boolean;
      function Get_Infrarrojos return Integer;
   private
      Distancia : Float := 0.0;
      S_I, S_D  : Boolean := False;
      Infra     : Integer := 0;
   end Datos_Sensores;

   protected Datos_7SEG is
      procedure Set_Seg1 (DL: Integer);
      procedure Set_Seg2 (UN: Integer);
      function Get_Seg1 return Integer;
      function Get_Seg2 return Integer;
   private
      Seg1, Seg2: Integer := 11; 
   end Datos_7SEG;

   protected Contador_ctrl is
      procedure Set_EN (x: Integer);
      function Get_EN return Integer;
   private
      EN: Integer := 0; 
   end Contador_ctrl;

   ----------------------------------------------------------------------
   -- PROCEDIMIENTOS PÚBLICOS
   ----------------------------------------------------------------------
   procedure Init;

   -- Funciones de lectura
   function leer_sensor_izquierda return Boolean;
   function leer_sensor_derecha return Boolean;
   function ReadButton0 return Boolean;
   function ReadButton1 return Boolean;
   function leer_ir1 return Boolean;
   function leer_ir2 return Boolean;
   function leer_ir3 return Boolean;
   function leer_ir4 return Boolean;
   function leer_ir5 return Boolean;

   -- Funciones de actuación
   procedure enviaSenyalON;
   procedure enviaSenyalOFF;
   function recibeSenyal return Boolean;
   procedure EnciendeRGB (color0, color1: RGBtype);
   
   -- Control Motores
   procedure Avanza;
   procedure Para;
   procedure Girar_Izq;
   procedure Girar_Der;
   procedure Corregir_Izq;
   procedure Corregir_Der;

   -- Tareas
   task Sensorizacion with CPU => 1;
   task PWM with CPU => 0;
   task Cuenta with CPU => 1;

end GPIO;