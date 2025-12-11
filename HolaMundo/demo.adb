with UART; use UART;
with Ada.Real_time;

procedure Demo is

 
begin
    -- UART0 => Cora board

   InitUART(nUart => 0);

   Put_Line("Hola Mundo");
   
   delay until Ada.Real_Time.Time_Last;
   
end Demo;

