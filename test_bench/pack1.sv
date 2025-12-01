

interface AES_intf;
    logic [127:0] in;
    logic [127:0] key;
    logic [127:0] out;

    // modport DUT (
    // input in,key,
    // output out
    // );

    // modport tb (
    // output in,key,
    // output out
    // );
endinterface

package pack1;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    class my_sequence_item extends uvm_sequence_item;
        `uvm_object_utils(my_sequence_item)
        rand bit[127:0] in;
        rand bit[127:0] key;
        bit [127:0]     out;
        function new(string name = "my_sequence_item");
            super.new(name);
        endfunction

    endclass

    class my_sequence1 extends uvm_sequence #(my_sequence_item);
        `uvm_object_utils(my_sequence1)
        my_sequence_item seq_item;

        function new(string name = "my_sequence1");
            super.new(name);
        endfunction

        task pre_body;
            seq_item = my_sequence_item::type_id::create("seq_item");
        endtask

        task body;
            repeat(4) begin
            start_item(seq_item);
                assert (seq_item.randomize())
            finish_item(seq_item);                
            end
        endtask
        
    endclass

    class my_sequence2 extends uvm_sequence #(my_sequence_item);
        `uvm_object_utils(my_sequence2)
        my_sequence_item seq_item;

        function new(string name = "my_sequence2");
            super.new(name);
        endfunction

        task pre_body;
            seq_item = my_sequence_item::type_id::create("seq_item");
        endtask

        task body;
            repeat(4) begin
            start_item(seq_item);
                assert (seq_item.randomize() )
            finish_item(seq_item);                
            end
        endtask

    endclass

    class my_driver extends uvm_driver #(my_sequence_item);
        `uvm_component_utils(my_driver)
        my_sequence_item seq_item;
        virtual AES_intf vin_drvr;
        
        function new(string name = "my_driver", uvm_component parent = null);
            super.new(name,parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if(!uvm_config_db #(virtual AES_intf)::get(this,"","vif_4",vin_drvr))
                `uvm_fatal(get_full_name(),"Couldn't get the virtual interface")

            seq_item = my_sequence_item::type_id::create("seq_item");
            $display("Build_phase, [Driver]");            
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            $display("Connect_phase, [Driver]");            
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            $display("Run_phase, [Driver]");
            forever begin
                seq_item_port.get_next_item(seq_item);
                    vin_drvr.in = seq_item.in;
                    vin_drvr.key = seq_item.key;       
                    $display("Interface Data_in = [%032h], key = [%032h]",vin_drvr.in,vin_drvr.key);
                    #1;
                seq_item_port.item_done();       
            end
            
        endtask
    endclass

    class my_monitor extends uvm_monitor;
        `uvm_component_utils(my_monitor)
        my_sequence_item seq_item;
        virtual AES_intf vin_mon;
        uvm_analysis_port#(my_sequence_item) my_analysis_port;

        function new(string name = "my_monitor", uvm_component parent = null);
            super.new(name,parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if(!uvm_config_db #(virtual AES_intf)::get(this,"","vif_4",vin_mon))
                `uvm_fatal(get_full_name(),"Couldn't get the virtual interface")

            my_analysis_port = new("my_analysis_port",this);
            $display("Build_phase, [Monitor]");            
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            $display("Connect_phase, [Monitor]");            
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            $display("Run_phase, [Monitor]");
            forever begin
                seq_item = my_sequence_item::type_id::create("seq_item");
                #1;
                $display("Monitor sampled: out = [%032h]",vin_mon.out);
                seq_item.out = vin_mon.out;
                seq_item.in  = vin_mon.in;
                seq_item.key = vin_mon.key;
                my_analysis_port.write(seq_item);
            end
            
        endtask
    endclass

    class my_sequencer extends uvm_sequencer #(my_sequence_item);
        `uvm_component_utils(my_sequencer)
        my_sequence_item seq_item;
        function new(string name = "my_sequencer", uvm_component parent = null);
            super.new(name,parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            seq_item = my_sequence_item::type_id::create("seq_item");
            $display("Build_phase, [sequencer]");            
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            $display("Connect_phase, [sequencer]");            
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            $display("Run_phase, [sequencer]");
        endtask
    endclass

    class my_agent extends uvm_agent;
        `uvm_component_utils(my_agent)
        my_driver     drvr; 
        my_monitor    mon ; 
        my_sequencer  sqr ;
        virtual AES_intf vin_3; 
        uvm_analysis_port #(my_sequence_item) agt_AP;
        function new(string name = "my_agent", uvm_component parent = null);
            super.new(name,parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if(!uvm_config_db #(virtual AES_intf)::get(this,"","vif_3",vin_3))
                `uvm_fatal(get_full_name(),"Couldn't get the virtual interface")
            uvm_config_db #(virtual AES_intf)::set(this,"*","vif_4",vin_3); // how to make * only drvr and mon??

            drvr = my_driver::type_id::create("drvr",this);
            mon  = my_monitor::type_id::create("mon",this);
            sqr  = my_sequencer::type_id::create("sqr",this);
            agt_AP = new("agt_AP",this);
            $display("Build_phase, [Agt]");            
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            $display("Connect_phase, [Agt]");
            mon.my_analysis_port.connect(agt_AP);
            drvr.seq_item_port.connect(sqr.seq_item_export);            
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            $display("Run_phase, [Agt]");
        endtask
    endclass

    class my_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(my_scoreboard)
        my_sequence_item seq_item;
        logic[127:0] exp_out;
        integer fd;
        uvm_analysis_imp #(my_sequence_item,my_scoreboard) AI;

        function new(string name = "my_scoreboard", uvm_component parent = null);
            super.new(name,parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            seq_item = my_sequence_item::type_id::create("seq_item");
            AI       = new("AI",this);
            $display("Build_phase, [scoreboard]");            
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            $display("Connect_phase, [scoreboard]");            
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            $display("Run_phase, [scoreboard]");
        endtask

        task write(my_sequence_item t);
            $display("scoreboard: in = [%032h], key = [%032h]",t.in,t.key);

            // NOTE: MAKE SURE THE PATH TO CODE AND FILES ARE RIGHT 
            // TIP : RUN THE PYTHON CODE ON TERMINAL FROM THE DIRECTORY 
            //       OF THE UVM SCOREBOARD TO CHECK NO ERRORS

            // Open file "key.txt" for writing
            fd = $fopen("./test_bench/key.txt","w");

            // Writing to file : First line writing the data , Second line writing the key
            $fdisplay(fd,"%h \n%h",t.in , t.key);

            // Close the "key.txt"
            $fclose(fd);

            // "$system" task to run the python code and interact with SCOREBOARD through I/O files
            $system($sformatf("python3 ./test_bench/ref.py"));

            // Open file "output.txt" for reading
            fd = $fopen("./test_bench/output.txt","r");

            // Reading the output of python code through "output.txt" file
            $fscanf(fd,"%h",exp_out);

            // Close the "output.txt"
            $fclose(fd);

            // COMPARE THE ACTUAL OUTPUT AND EXPECTED OUTPUT
            if(exp_out == t.out)
                $display("SUCCESS , OUT IS %h and EXP OUT IS %h ", t.out , exp_out);
            else 
                $error("FAILURE , OUT IS %h and EXP OUT IS %h ", t.out , exp_out); 
        endtask
    endclass

    class my_subscriber extends uvm_subscriber #(my_sequence_item);
        `uvm_component_utils(my_subscriber)
        my_sequence_item seq_item;
        function new(string name = "my_subscriber", uvm_component parent = null);
            super.new(name,parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            seq_item = my_sequence_item::type_id::create("seq_item");
            $display("Build_phase, [subscriber]");            
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            $display("Connect_phase, [subscriber]");            
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            $display("Run_phase, [subscriber]");
        endtask
        
        function void write(my_sequence_item t);
            $display("subscriber: in=[%032h],key=[%032h],out=[%032h]",t.in,t.key,t.out);
        endfunction
    endclass

    class my_env extends uvm_env;
        `uvm_component_utils(my_env)
        my_subscriber sub ; 
        my_scoreboard sb  ; 
        my_agent      agt ;
        virtual AES_intf vin_2; 
        function new(string name = "my_env", uvm_component parent = null);
            super.new(name,parent);
        endfunction

        
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if(!uvm_config_db #(virtual AES_intf)::get(this,"","vif_2",vin_2))
                `uvm_fatal(get_full_name(),"Couldn't get the virtual interface")
            uvm_config_db #(virtual AES_intf)::set(this,"agt","vif_3",vin_2);

            agt = my_agent::type_id::create("agt",this);
            sub = my_subscriber::type_id::create("sub",this);
            sb  = my_scoreboard::type_id::create("sb",this);
            $display("Build_phase, [env]");            
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            agt.agt_AP.connect(sb.AI);
            agt.agt_AP.connect(sub.analysis_export); // pre defined uvm_analysis_imp in the class uvm_subscriber
            $display("Connect_phase, [env]");            
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            $display("Run_phase, [env]");
        endtask
    endclass

    class my_test extends uvm_test;
        `uvm_component_utils(my_test)
         
        my_env env ;
        virtual AES_intf vin_1;
        my_sequence1 seq1;
        my_sequence2 seq2; 
        function new(string name = "my_test", uvm_component parent = null);
            super.new(name,parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            $display("Build_phase, [test]");
            if(!uvm_config_db #(virtual AES_intf)::get(this,"","vif_1",vin_1))
                `uvm_fatal(get_full_name(),"Couldn't get the virtual interface")
            
            uvm_config_db #(virtual AES_intf)::set(this,"env","vif_2",vin_1);
            env  = my_env::type_id::create("env",this);
            seq1 = my_sequence1::type_id::create("seq1");
            seq2 = my_sequence2::type_id::create("seq2");
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            $display("Connect_phase, [test]");            
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            $display("Run_phase, [test]");
            phase.raise_objection(this);
                seq1.start(env.agt.sqr);
                seq2.start(env.agt.sqr);
            phase.drop_objection(this);
        endtask
    endclass

endpackage

 