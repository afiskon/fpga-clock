`default_nettype none

module encode_digit(input [3:0] digit, input hide, output [0:6] seg);
    assign seg = (hide == 1) ? 0 :
                    (digit == 0) ? 8'b1111110:
                    (digit == 1) ? 8'b0110000:
                    (digit == 2) ? 8'b1101101:
                    (digit == 3) ? 8'b1111001:
                    (digit == 4) ? 8'b0110011:
                    (digit == 5) ? 8'b1011011:
                    (digit == 6) ? 8'b1011111:
                    (digit == 7) ? 8'b1110000:
                    (digit == 8) ? 8'b1111111:
                    (digit == 9) ? 8'b1111011:
                                   8'b1001111; // E for Error
endmodule

module inc_minute(input [3:0] min1, input [3:0] min2,
                  output [3:0] out_min1, output [3:0] out_min2);
    assign out_min1 = (min1 == 9) ? 0 : min1 + 1;
    assign out_min2 = (min1 == 9) ?
        ( (min2 == 5) ? 0 : min2 + 1 )
        : min2;
endmodule

module inc_hour(input [3:0] hour1, input [3:0] hour2,
                output [3:0] out_hour1, output [3:0] out_hour2);
    assign out_hour1 =
        (((hour2 != 2)&&(hour1 == 9)) || ((hour2 == 2)&&(hour1 == 3)))
        ? 0 : hour1 + 1;

    assign out_hour2 = 
        ((hour2 == 2) && (hour1 == 3))
        ? 0 : ( (hour1 == 9) ? hour2 + 1 : hour2 );
endmodule

module top(input clk,
           input btn_set, input btn_inc,
           output [0:7] seg, output [0:3] d);
    reg [23:0] divider = 0;
    reg [3:0] d_rot = 4'b1110;
    reg [5:0] sec = 0;

    // the time is displayed like this:
    // hour2 hour1 : min2 min1
    reg [3:0] min1 = 0; 
    reg [3:0] min2 = 0;
    reg [3:0] hour1 = 0;
    reg [3:0] hour2 = 0;

    reg [3:0] next_min1;
    reg [3:0] next_min2;
    reg [3:0] next_hour1;
    reg [3:0] next_hour2;

    reg [1:0] current_set = 0;
    reg btn_set_was_pressed = 0;
    reg btn_inc_was_pressed = 0;

    inc_minute im(min1, min2, next_min1, next_min2);
    inc_hour ih(hour1, hour2, next_hour1, next_hour2);

    always @(posedge clk)
    begin
        if(divider[9:0] == 0)
            d_rot <= { d_rot[2:0], d_rot[3] };

        if(divider[14:0] == 0)
        begin
            if(btn_set == 1)
                btn_set_was_pressed <= 1;
            else
            begin
                if(btn_set_was_pressed == 1)
                    current_set <= (current_set == 2)
                                   ? 0 : current_set + 1;

                btn_set_was_pressed <= 0;
            end

            if(btn_inc == 1)
                btn_inc_was_pressed <= 1;
            else
            begin
                if(btn_inc_was_pressed == 1)
                begin
                    if(current_set == 1)
                    begin
                        hour1 <= next_hour1;
                        hour2 <= next_hour2;
                        sec <= 0;
                        divider <= 0;
                    end
                    else if(current_set == 2)
                    begin
                        min1 <= next_min1;
                        min2 <= next_min2;
                        sec <= 0;
                        divider <= 0;
                    end
                end

                btn_inc_was_pressed <= 0;
            end

        end

        // once a second @ 12 MHz oscillator
        if(divider == 12000000)
        begin
            divider <= 0;
            sec <= (sec == 59) ? 0 : sec + 1;

            if(sec == 59)
            begin
                min1 <= next_min1;
                min2 <= next_min2;
                if((min1 == 9) && (min2 == 5))
                begin
                    hour1 <= next_hour1;
                    hour2 <= next_hour2;
                end
            end
        end
        else 
            divider <= divider + 1;
    end // always ...
  
    assign d = d_rot;

    reg [3:0] disp;
    assign disp = (d_rot == 4'b1110) ? min1:
                  (d_rot == 4'b1101) ? min2:
                  (d_rot == 4'b1011) ? hour1:
                  (d_rot == 4'b0111) ? hour2:
                  13; // should never happen

    reg hide_seg = (((current_set == 1) &&
                     ((d_rot == 4'b0111) || (d_rot == 4'b1011))) ||
                    ((current_set == 2) &&
                     ((d_rot == 4'b1101) || (d_rot == 4'b1110)))) &&
                    (sec[0] == 1);
    encode_digit enc1(disp, hide_seg, seg[0:6]);
    assign seg[7] = (d_rot == 4'b1011) && (sec[0] == 1);

endmodule
