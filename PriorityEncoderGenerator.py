
F_bit = 23
E_bit = 8

#该代码用于生成并行优先编码器，用于浮点型减法运算对齐
f = open("encoder.v","w+")
f.write("module encoder(add_f1,sub_shift);\n\n")
f.write("parameter E_bit = %d,F_bit = %d;\n\n"%(E_bit,F_bit+1))
f.write("input wire[%d:0] add_f1;\noutput reg[%d:0] sub_shift;\n\n"%(F_bit+2,E_bit-1))
f.write("always @(add_f1) begin\n\tcasex(add_f1)\n")
for i in range(0,F_bit+2):
    f.write("\t\t%d\'b"%(F_bit+2))
    a = ""
    for j in range(0,i):
        a += "0"
    a+="1"
    for j in range(i,F_bit+1):
        a += "x"
    f.write(a)
    f.write(": sub_shift=%d'h%d"%(E_bit-1,i))
    f.write(";\n")
f.write("\t\tdefault: sub_shift = %d'h0;\n"%(E_bit-1))
f.write("\tendcase\nend\nendmodule\n\n")
f.close()
