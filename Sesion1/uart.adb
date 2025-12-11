with System; use System;
with System.Storage_Elements; 
package body UART is

  type GAP is array (1..4) of Integer;

  type ZYNQ_UART is record
    CONTROL : Integer;
    MODE : Integer;       -- offset: 0x04
    GAP0: GAP;
    BRGEN : Integer;      -- offset: 0x18
    GAP1: GAP;    
    STS_TXEMPTY : Integer;     -- offset: 0x2C
    TX_FIFO : Integer;      -- offset: 0x30
    BRDIV : Integer;      -- offset: 0x34
  end record;


  UART0 : ZYNQ_UART;
  UART1 : ZYNQ_UART;

  for UART0 use at System.Storage_Elements.To_Address(16#e0000000#);
  for UART1 use at System.Storage_Elements.To_Address(16#e0001000#);

  uart_id : Integer;

--  for ZYNQ_UART0_CONTROL use at System.Storage_Elements.To_Address(16#e0000000#);
--  for ZYNQ_UART0_MODE use at System.Storage_Elements.To_Address(16#e0000004#);
--  for ZYNQ_UART0_BRGEN use at System.Storage_Elements.To_Address(16#e0000018#);
--  for ZYNQ_UART0_BRDIV use at System.Storage_Elements.To_Address(16#e0000034#);
--  for ZYNQ_UART0_CN_STS use at System.Storage_Elements.To_Address(16#e000002C#);
--  for ZYNQ_UART0_STS_TXEMPTY use at System.Storage_Elements.To_Address(16#e000002C#);
--  for ZYNQ_UART0_TX_FIFO use at System.Storage_Elements.To_Address(16#e0000030#);

  procedure InitUART(nUart : integer) is 
  begin
    uart_id := nUart;
    if (uart_id = 0) then
      UART0.CONTROL := 0;
      UART0.BRDIV := 6;
      UART0.BRGEN := 124;
      UART0.MODE := 16#20#;
      UART0.CONTROL := 16#17#;
        -- ZYNQ_UART_CR_TXEN | ZYNQ_UART_CR_RXEN | ZYNQ_UART_CR_TXRES | ZYNQ_UART_CR_RXRES
    elsif (uart_id = 1) then
      UART1.CONTROL := 0;
      UART1.BRDIV := 6;
      UART1.BRGEN := 124;
      UART1.MODE := 16#20#;
      UART1.CONTROL := 16#17#;
        -- ZYNQ_UART_CR_TXEN | ZYNQ_UART_CR_RXEN | ZYNQ_UART_CR_TXRES | ZYNQ_UART_CR_RXRES
    end if;
  end InitUART;

  procedure Put(ch : Character) is
  begin
    if (uart_id = 0) then
       while(UART0.STS_TXEMPTY = 0) loop
         null;
       end loop;
       UART0.TX_FIFO := character'pos(ch);
    elsif (uart_id = 1) then
       while(UART1.STS_TXEMPTY = 0) loop
         null;
       end loop;
       UART1.TX_FIFO := character'pos(ch);
    end if;
  end Put;

  procedure New_Line is
  begin
    if (uart_id = 0) then
       UART0.TX_FIFO := 10;
       UART0.TX_FIFO := 13;
    elsif (uart_id = 1) then
       UART1.TX_FIFO := 10;
       UART1.TX_FIFO := 13;
    end if;  
  end New_Line;

  procedure Put(st : String) is
  begin
    for i in st'first..st'last loop
       Put(st(i));
    end loop;
  end Put;

  procedure Put_Line(ch : Character) is
  begin
    Put(ch);
    New_Line;
  end Put_Line;

  procedure Put_Line(st : String) is
  begin
    Put(st);
    New_Line;
  end Put_Line;

  procedure Put(int : Integer) is
  begin
    Put(Integer'Image(int));
  end Put;


end UART;
