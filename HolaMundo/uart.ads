package UART is

  procedure InitUART(nUart : integer);

  procedure Put(ch : Character);
  procedure Put(st : String);
  procedure Put(int: Integer);
  procedure Put_Line(ch : Character);
  procedure Put_Line(st : String);
  procedure New_Line;

end UART;
