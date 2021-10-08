module decoder 
(
    input wire data_in,
    input wire rx_sync,
    output reg [2:0] A,
    output reg [2:0] B,
    output reg [2:0] C,
    output reg [2:0] D,
    output reg [19:0] Rg,
    output reg valid,  
    input clk, 
    input rst
);

    reg [821:0]d;
    wire F1,F2,F3;
    wire A1,A2,A3;
    wire B1,B2,B3;
    wire C1,C2,C3;
    wire D1,D2,D3; 
    
    reg [20:0] cnt;
 
    wire F_pw1,F_pw2,F_pw3; //F1
    wire F_pw4,F_pw5,F_pw6; //F2
    wire F_pw7,F_pw8,F_pw9; //F3
    
    wire A_pw1, A_pw2, A_pw3; //A1
    wire A_pw4, A_pw5, A_pw6; //A2
    wire A_pw7, A_pw8, A_pw9; //A3
    
    wire B_pw1, B_pw2, B_pw3; //B1
    wire B_pw4, B_pw5, B_pw6; //B2
    wire B_pw7, B_pw8, B_pw9; //B3   
    
    wire C_pw1, C_pw2, C_pw3; //C1
    wire C_pw4, C_pw5, C_pw6; //C2
    wire C_pw7, C_pw8, C_pw9; //C3   
    
    wire D_pw1, D_pw2, D_pw3; //D1
    wire D_pw4, D_pw5, D_pw6; //D2
    wire D_pw7, D_pw8, D_pw9; //D3   
    
    reg [416:0] d_g;
    reg or_gab;
    
    wire D1_g, D2_g, D3_g;
    wire D4_g, D5_g, D6_g;
    wire D7_g, D8_g, D9_g;
    wire D10_g, D11_g, D12_g;
     
    always @(posedge clk, posedge rst)
    begin
        if (~rst)
            begin
                d <= 0;
                d_g <= 0;
                or_gab <= 0;
                cnt <= 1;
                A <= 0;
                B <= 0;
                C <= 0;
                D <= 0;
                Rg <= 0;
                valid <= 0;
            end
        else 
            begin
                if (rx_sync) 
                    begin
                        d <= d << 1 ;
                        d[0] <= data_in;
                    
                        d_g <= d_g << 1 ;
                        d_g[0] <= or_gab;
                            
                        if ((F3 & F2 ) | (F1 & F2)) 
                            or_gab <= 1; 
                        else
                            or_gab <= 0;
                        
                        cnt <= cnt + 1;
                    
                        if (F1 & F2 ) 
                            begin
                                if (~(D1_g | D2_g | D3_g | D4_g | D5_g | D6_g | D7_g | D8_g | D9_g | D10_g | D11_g | D12_g)) 
                                    begin
                                        valid <= 1;
                                        A <= (A3 << 2) | (A2 << 1) | A1;
                                        B <= (B3 << 2) | (B2 << 1) | B1;
                                        C <= (C3 << 2) | (C2 << 1) | C1;
                                        D <= (D3 << 2) | (D2 << 1) | D1;
                                        Rg <= ((cnt - 821) * 15)>> 1;
                                    end
                            end 
                        else 
                            begin
                                A <= 0;
                                B <= 0;
                                C <= 0;
                                D <= 0;
                                Rg <= 0;
                                valid <= 0; 
                            end
                    end
                else
                    cnt <= 1;
            end    
    end
    
    assign or_notgate = (~(D1_g | D2_g | D3_g | D4_g | D5_g | D6_g | D7_g | D8_g | D9_g | D10_g | D11_g | D12_g));
        
    assign F_pw1 = d[0] & d[1] & d[2] & d[3] & d[4] & d[5] & d[6] & d[7];
    assign F_pw2 = d[0] & d[1] & d[2] & d[3] & d[4] & d[5] & d[6] & d[7] & d[8];
    assign F_pw3 = d[0] & d[1] & d[2] & d[3] & d[4] & d[5] & d[6] & d[7] & d[8] & d[9];
    assign F3 = F_pw1 || F_pw2 || F_pw3;
    
    assign F_pw4 = d[406] & d[407] & d[408] & d[409] & d[410] & d[411] & d[412] & d[413];
    assign F_pw5 = d[406] & d[407] & d[408] & d[409] & d[410] & d[411] & d[412] & d[413] & d[414] ;
    assign F_pw6 = d[406] & d[407] & d[408] & d[409] & d[410] & d[411] & d[412] & d[413] & d[414] & d[415];
    assign F2 = F_pw4 || F_pw5 || F_pw6;    

    assign F_pw7 = d[812] & d[813] & d[814] & d[815] & d[816] & d[817] & d[818] & d[819];
    assign F_pw8 = d[812] & d[813] & d[814] & d[815] & d[816] & d[817] & d[818] & d[819] & d[820];
    assign F_pw9 = d[812] & d[813] & d[814] & d[815] & d[816] & d[817] & d[818] & d[819] & d[820] & d[821];
    assign F1 = F_pw7 || F_pw8 || F_pw9;      
    
    //Decode Processor
    
    assign D_pw1 = d[435] & d[436] & d[437] & d[438] & d[439] & d[440] & d[441] & d[442];
    assign D_pw2 = d[435] & d[436] & d[437] & d[438] & d[439] & d[440] & d[441] & d[442] & d[443];
    assign D_pw3 = d[435] & d[436] & d[437] & d[438] & d[439] & d[440] & d[441] & d[442] & d[443] & d[444];
    assign D3 = (F1&F2) ? (D_pw1 || D_pw2 || D_pw3) : 0;
    
    assign B_pw1 = d[464] & d[465] & d[466] & d[467] & d[468] & d[469] & d[470] & d[471] ;
    assign B_pw2 = d[464] & d[465] & d[466] & d[467] & d[468] & d[469] & d[470] & d[471] & d[472] ;
    assign B_pw3 = d[464] & d[465] & d[466] & d[467] & d[468] & d[469] & d[470] & d[471] & d[472] & d[473];
    assign B3 = (F1&F2) ? (B_pw1 || B_pw2 || B_pw3) : 0;
    
    assign D_pw4 = d[493] & d[494] & d[495] & d[496] & d[497] & d[498] & d[499] & d[500];
    assign D_pw5 = d[493] & d[494] & d[495] & d[496] & d[497] & d[498] & d[499] & d[500] & d[501] ;
    assign D_pw6 = d[493] & d[494] & d[495] & d[496] & d[497] & d[498] & d[499] & d[500] & d[501] & d[502];
    assign D2 = (F1&F2) ? (D_pw4 || D_pw5 || D_pw6) : 0;    
   
    assign B_pw4 = d[522] & d[523] & d[524] & d[525] & d[526] & d[527] & d[528] & d[529];
    assign B_pw5 = d[522] & d[523] & d[524] & d[525] & d[526] & d[527] & d[528] & d[529] & d[530] ;
    assign B_pw6 = d[522] & d[523] & d[524] & d[525] & d[526] & d[527] & d[528] & d[529] & d[530] & d[531];
    assign B2 = (F1&F2) ? (B_pw4 || B_pw5 || B_pw6) : 0;    

    assign D_pw7 = d[551] & d[552] & d[553] & d[554] & d[555] & d[556] & d[557] & d[558];
    assign D_pw8 = d[551] & d[552] & d[553] & d[554] & d[555] & d[556] & d[557] & d[558] & d[559];
    assign D_pw9 = d[551] & d[552] & d[553] & d[554] & d[555] & d[556] & d[557] & d[558] & d[559] & d[560];
    assign D1 = (F1&F2) ? (D_pw7 || D_pw8 || D_pw9) :0; 
    
    assign B_pw7 = d[580] & d[581] & d[582] & d[583] & d[584] & d[585] & d[586] & d[587];
    assign B_pw8 = d[580] & d[581] & d[582] & d[583] & d[584] & d[585] & d[586] & d[587] & d[588];
    assign B_pw9 = d[580] & d[581] & d[582] & d[583] & d[584] & d[585] & d[586] & d[587] & d[588] & d[589];
    assign B1 = (F1&F2) ? (B_pw7 || B_pw8 || B_pw9) : 0;     
    
    assign A_pw1 = d[638] & d[639] & d[640] & d[641] & d[642] & d[643] & d[644] & d[645];
    assign A_pw2 = d[638] & d[639] & d[640] & d[641] & d[642] & d[643] & d[644] & d[645] & d[646];
    assign A_pw3 = d[638] & d[639] & d[640] & d[641] & d[642] & d[643] & d[644] & d[645] & d[646] & d[647];
    assign A3 = (F1&F2) ? (A_pw1 || A_pw2 || A_pw3) : 0;
    
    assign C_pw1 = d[667] & d[668] & d[669] & d[670] & d[671] & d[672] & d[673] & d[674] ;
    assign C_pw2 = d[667] & d[668] & d[669] & d[670] & d[671] & d[672] & d[673] & d[674] & d[675] ;
    assign C_pw3 = d[667] & d[668] & d[669] & d[670] & d[671] & d[672] & d[673] & d[674] & d[675] & d[676];
    assign C3 = (F1&F2) ? (C_pw1 || C_pw2 || C_pw3) : 0;
    
    assign A_pw4 = d[696] & d[697] & d[698] & d[699] & d[700] & d[701] & d[702] & d[703];
    assign A_pw5 = d[696] & d[697] & d[698] & d[699] & d[700] & d[701] & d[702] & d[703] & d[704] ;
    assign A_pw6 = d[696] & d[697] & d[698] & d[699] & d[700] & d[701] & d[702] & d[703] & d[704] & d[705];
    assign A2 = (F1&F2) ? (A_pw4 || A_pw5 || A_pw6) : 0;    
   
    assign C_pw4 = d[725] & d[726] & d[727] & d[728] & d[729] & d[730] & d[731] & d[732];
    assign C_pw5 = d[725] & d[726] & d[727] & d[728] & d[729] & d[730] & d[731] & d[732] & d[733] ;
    assign C_pw6 = d[725] & d[726] & d[727] & d[728] & d[729] & d[730] & d[731] & d[732] & d[733] & d[734];
    assign C2 = (F1&F2) ? (C_pw4 || C_pw5 || C_pw6) : 0;    

    assign A_pw7 = d[754] & d[755] & d[756] & d[757] & d[758] & d[759] & d[760] & d[761];
    assign A_pw8 = d[754] & d[755] & d[756] & d[757] & d[758] & d[759] & d[760] & d[761] & d[762];
    assign A_pw9 = d[754] & d[755] & d[756] & d[757] & d[758] & d[759] & d[760] & d[761] & d[762] & d[763];
    assign A1 = (F1&F2) ? (A_pw7 || A_pw8 || A_pw9) : 0; 
    
    assign C_pw7 = d[783] & d[784] & d[785] & d[786] & d[787] & d[788] & d[789] & d[790];
    assign C_pw8 = d[783] & d[784] & d[785] & d[786] & d[787] & d[788] & d[789] & d[790] & d[791];
    assign C_pw9 = d[783] & d[784] & d[785] & d[786] & d[787] & d[788] & d[789] & d[790] & d[791] & d[792];
    assign C1 = (F1&F2) ? (C_pw7 || C_pw8 || C_pw9) : 0;
        
    // garble processor
    assign D1_g = d_g[27];
    assign D2_g = d_g[56];
    assign D3_g = d_g[85];  
    assign D4_g = d_g[114];    
    assign D5_g = d_g[143]; 
    assign D6_g = d_g[172];     
    assign D7_g = d_g[201];
    assign D8_g = d_g[230];
    assign D9_g = d_g[259];
    assign D10_g = d_g[288];    
    assign D11_g = d_g[346]; 
    assign D12_g = d_g[375];
    
endmodule