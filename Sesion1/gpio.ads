with System.storage_elements;
with System.Multiprocessors;
use System.Multiprocessors;

package GPIO is

MI, MD: boolean;

   --botones
   type ButtonState is (Off, On);
   for ButtonState use ( Off => 2#0#, On => 2#1#);
   for ButtonState 'Size use 1;

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


   --leds GRB
   type RGBtype is (off, red, green, blue, violet);
   for RGBtype use (
                    off=>2#000#,
                    red=>2#001#,
                    green=>2#010#,
                    blue=>2#100#,
                    violet=>2#101#);
   for RGBtype'Size use 3;

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


   -- Motor (conexión JA) - Pmod Leds 8LD
   type sentido is (parado, atras, adelante);
   for sentido use (
                    parado=>2#00#,
                    atras=>2#01#,
                    adelante=>2#10#);
   for sentido'Size use 2;

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


   -- Infrarrojos IRF (conexión JB)
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

      -- Infrarrojos IRI (Conexion JB)
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

   -- Ultrasonidos
   type Ctrl_Ultra is record
      trigger : Boolean; --out
      echo : Boolean; --in
   end record;

   for Ctrl_Ultra use record
      trigger at 0 range 1..1;
      echo at 0 range 0..0;
   end record;

   type GPIO_Ultra is record
      datos : Ctrl_Ultra;
      control : Integer;
   end record;


   --Display 7S
   type D_type is (off, D1, D7, D0, D3, D2, D6, D4, D9, D5, D11, D8);
   for D_type use (
                   off=>2#0000000#,
                   D1=>2#0000110#,
                   D7=>2#0000111#,
                   D0=>2#0111111#,
                   D3=>2#1001111#,
                   D2=>2#1011011#,
                   D6=>2#1011111#,
                   D4=>2#1100110#,
                   D9=>2#1100111#,
                   D5=>2#1101101#,
                   D11=>2#1110111#,
                   D8=>2#1111111#
                  );
   for D_type'Size use 7;

   type Disp is record
      D_num : D_type; --out
      Cat : Boolean;
   end record;

   for Disp use record
      D_num at 0 range 4..10;
      Cat at 0 range 11..11; --selecci n del display (drch o izq)
   end record;



   protected Datos_Sensores is
      procedure Set_Distancia (D : Float); -- Ultrasonidos
      procedure Set_Frontales (B1, B2 : Boolean); -- IRF
      procedure Set_Infrarrojos (I : Integer); -- IRI

      function Get_Distancia return Float; -- Ultrasonidos
      function Get_S_I return Boolean; -- IRF2
      function Get_S_D return Boolean; -- IRF1
      function Get_Infrarrojos return Integer;  -- IRI
   private
      Distancia : Float := 0.0;
      S_I, S_D    : Boolean := False;
      Infra    : Integer := 0;
   end Datos_Sensores;

   procedure Init;

   function leer_sensor_izquierda return Boolean;
   function leer_sensor_derecha return Boolean;
   function ReadButton0 return Boolean;
   function ReadButton1 return Boolean;
   procedure EnciendeRGB (color0, color1: RGBtype);

   function leer_ir1 return Boolean;
   function leer_ir2 return Boolean;
   function leer_ir3 return Boolean;
   function leer_ir4 return Boolean;
   function leer_ir5 return Boolean;

   task Sensorizacion with CPU => 1;


end GPIO;
