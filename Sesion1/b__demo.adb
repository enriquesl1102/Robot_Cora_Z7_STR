pragma Warnings (Off);
pragma Ada_95;
pragma Source_File_Name (ada_main, Spec_File_Name => "b__demo.ads");
pragma Source_File_Name (ada_main, Body_File_Name => "b__demo.adb");
pragma Suppress (Overflow_Check);

package body ada_main is

   E084 : Short_Integer; pragma Import (Ada, E084, "ada__tags_E");
   E017 : Short_Integer; pragma Import (Ada, E017, "ada__exceptions_E");
   E042 : Short_Integer; pragma Import (Ada, E042, "system__soft_links_E");
   E099 : Short_Integer; pragma Import (Ada, E099, "system__bb__timing_events_E");
   E040 : Short_Integer; pragma Import (Ada, E040, "system__exception_table_E");
   E006 : Short_Integer; pragma Import (Ada, E006, "ada__real_time_E");
   E110 : Short_Integer; pragma Import (Ada, E110, "system__tasking__protected_objects_E");
   E116 : Short_Integer; pragma Import (Ada, E116, "system__tasking__restricted__stages_E");
   E119 : Short_Integer; pragma Import (Ada, E119, "uart_E");
   E106 : Short_Integer; pragma Import (Ada, E106, "gpio_E");

   Sec_Default_Sized_Stacks : array (1 .. 2) of aliased System.Secondary_Stack.SS_Stack (System.Parameters.Runtime_Default_Sec_Stack_Size);

   Local_Priority_Specific_Dispatching : constant String := "";
   Local_Interrupt_States : constant String := "";

   Is_Elaborated : Boolean := False;

   procedure adafinal is
      procedure s_stalib_adafinal;
      pragma Import (Ada, s_stalib_adafinal, "system__standard_library__adafinal");

      procedure Runtime_Finalize;
      pragma Import (C, Runtime_Finalize, "__gnat_runtime_finalize");

   begin
      if not Is_Elaborated then
         return;
      end if;
      Is_Elaborated := False;
      Runtime_Finalize;
      s_stalib_adafinal;
   end adafinal;

   procedure adainit is
      Main_Priority : Integer;
      pragma Import (C, Main_Priority, "__gl_main_priority");
      Time_Slice_Value : Integer;
      pragma Import (C, Time_Slice_Value, "__gl_time_slice_val");
      WC_Encoding : Character;
      pragma Import (C, WC_Encoding, "__gl_wc_encoding");
      Locking_Policy : Character;
      pragma Import (C, Locking_Policy, "__gl_locking_policy");
      Queuing_Policy : Character;
      pragma Import (C, Queuing_Policy, "__gl_queuing_policy");
      Task_Dispatching_Policy : Character;
      pragma Import (C, Task_Dispatching_Policy, "__gl_task_dispatching_policy");
      Priority_Specific_Dispatching : System.Address;
      pragma Import (C, Priority_Specific_Dispatching, "__gl_priority_specific_dispatching");
      Num_Specific_Dispatching : Integer;
      pragma Import (C, Num_Specific_Dispatching, "__gl_num_specific_dispatching");
      Main_CPU : Integer;
      pragma Import (C, Main_CPU, "__gl_main_cpu");
      Interrupt_States : System.Address;
      pragma Import (C, Interrupt_States, "__gl_interrupt_states");
      Num_Interrupt_States : Integer;
      pragma Import (C, Num_Interrupt_States, "__gl_num_interrupt_states");
      Unreserve_All_Interrupts : Integer;
      pragma Import (C, Unreserve_All_Interrupts, "__gl_unreserve_all_interrupts");
      Detect_Blocking : Integer;
      pragma Import (C, Detect_Blocking, "__gl_detect_blocking");
      Default_Stack_Size : Integer;
      pragma Import (C, Default_Stack_Size, "__gl_default_stack_size");
      Default_Secondary_Stack_Size : System.Parameters.Size_Type;
      pragma Import (C, Default_Secondary_Stack_Size, "__gnat_default_ss_size");
      Bind_Env_Addr : System.Address;
      pragma Import (C, Bind_Env_Addr, "__gl_bind_env_addr");

      procedure Runtime_Initialize (Install_Handler : Integer);
      pragma Import (C, Runtime_Initialize, "__gnat_runtime_initialize");
      procedure Start_Slave_CPUs;
      pragma Import (C, Start_Slave_CPUs, "__gnat_start_slave_cpus");
      Binder_Sec_Stacks_Count : Natural;
      pragma Import (Ada, Binder_Sec_Stacks_Count, "__gnat_binder_ss_count");
      Default_Sized_SS_Pool : System.Address;
      pragma Import (Ada, Default_Sized_SS_Pool, "__gnat_default_ss_pool");

   begin
      if Is_Elaborated then
         return;
      end if;
      Is_Elaborated := True;
      Main_Priority := -1;
      Time_Slice_Value := 0;
      WC_Encoding := 'b';
      Locking_Policy := 'C';
      Queuing_Policy := ' ';
      Task_Dispatching_Policy := 'F';
      Priority_Specific_Dispatching :=
        Local_Priority_Specific_Dispatching'Address;
      Num_Specific_Dispatching := 0;
      Main_CPU := -1;
      Interrupt_States := Local_Interrupt_States'Address;
      Num_Interrupt_States := 0;
      Unreserve_All_Interrupts := 0;
      Detect_Blocking := 1;
      Default_Stack_Size := -1;

      ada_main'Elab_Body;
      Default_Secondary_Stack_Size := System.Parameters.Runtime_Default_Sec_Stack_Size;
      Binder_Sec_Stacks_Count := 2;
      Default_Sized_SS_Pool := Sec_Default_Sized_Stacks'Address;

      Runtime_Initialize (1);

      Ada.Exceptions'Elab_Spec;
      System.Soft_Links'Elab_Spec;
      System.Bb.Timing_Events'Elab_Spec;
      E099 := E099 + 1;
      Ada.Tags'Elab_Body;
      E084 := E084 + 1;
      System.Exception_Table'Elab_Body;
      E040 := E040 + 1;
      E042 := E042 + 1;
      E017 := E017 + 1;
      Ada.Real_Time'Elab_Body;
      E006 := E006 + 1;
      System.Tasking.Protected_Objects'Elab_Body;
      E110 := E110 + 1;
      System.Tasking.Restricted.Stages'Elab_Body;
      E116 := E116 + 1;
      UART'ELAB_BODY;
      E119 := E119 + 1;
      GPIO'ELAB_SPEC;
      GPIO'ELAB_BODY;
      E106 := E106 + 1;
      Start_Slave_CPUs;
   end adainit;

   procedure Ada_Main_Program;
   pragma Import (Ada, Ada_Main_Program, "_ada_demo");

   procedure main is
      procedure Initialize (Addr : System.Address);
      pragma Import (C, Initialize, "__gnat_initialize");

      procedure Finalize;
      pragma Import (C, Finalize, "__gnat_finalize");
      SEH : aliased array (1 .. 2) of Integer;

      Ensure_Reference : aliased System.Address := Ada_Main_Program_Name'Address;
      pragma Volatile (Ensure_Reference);

   begin
      Initialize (SEH'Address);
      adainit;
      Ada_Main_Program;
      adafinal;
      Finalize;
   end;

--  BEGIN Object file/option list
   --   C:\Users\enriq\Desktop\Proyecto\Sesion1\uart.o
   --   C:\Users\enriq\Desktop\Proyecto\Sesion1\gpio.o
   --   C:\Users\enriq\Desktop\Proyecto\Sesion1\demo.o
   --   -LC:\Users\enriq\Desktop\Proyecto\Sesion1\
   --   -LC:\Users\enriq\Desktop\Proyecto\Sesion1\
   --   -LC:\gnat2020-arm\arm-eabi\lib\gnat\ravenscar-full-zynq7000\adalib\
   --   -static
   --   -lgnarl
   --   -lgnat
--  END Object file/option list   

end ada_main;
