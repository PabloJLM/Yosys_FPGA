// Demo de varios módulos para la Tang Nano 9K.
// S1 (pin 4) es reset, S2 (pin 3) cambia el patrón de los LEDs.
module top (
    input        sys_clk,               // 27 MHz
    input        sys_rst_n,             // botón S1, activo en bajo
    input        btn_n,                 // botón S2, activo en bajo
    output [5:0] led                    // LEDs activos en bajo
);

wire tick;
wire pulso;
reg  [1:0] modo;
wire [5:0] patron;

tick_gen #(.PERIODO(27_000_000 / 8)) u_tick (   // 8 pasos por segundo
    .clk   (sys_clk),
    .rst_n (sys_rst_n),
    .tick  (tick)
);

debounce u_boton (
    .clk   (sys_clk),
    .rst_n (sys_rst_n),
    .btn_n (btn_n),
    .pulso (pulso)
);

always @(posedge sys_clk or negedge sys_rst_n)
    if (!sys_rst_n) modo <= 2'd0;
    else if (pulso) modo <= modo + 1'b1;

patrones u_patrones (
    .clk   (sys_clk),
    .rst_n (sys_rst_n),
    .tick  (tick),
    .modo  (modo),
    .leds  (patron)
);

assign led = ~patron;                   // la placa enciende con 0

endmodule
