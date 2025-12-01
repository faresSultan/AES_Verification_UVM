
module top_level();
    import uvm_pkg::*;
    import pack1::*;

    AES_intf in1 ();
    AES_Encrypt DUT (.in(in1.in),.key(in1.key),.out(in1.out));

    initial begin
        uvm_config_db #(virtual AES_intf )::set(null,"uvm_test_top","vif_1",in1);
        run_test("my_test");  // finish on completion
    end
    
endmodule

