import os

f = r"c:\Users\tonne\SITES\mediare_mgcf\Projeto Mediare Doc\MEDIARE__MGCF__MEDIADOR_DE_GUARDA__COM.txt"
out_file = r"c:\Users\tonne\SITES\mediare_mgcf\docs_summary2.txt"

with open(out_file, "w", encoding="utf-8") as out:
    try:
        with open(f, "r", encoding="latin-1") as file:
            content = file.read()
            out.write(content)
    except Exception as e:
        out.write(f"Error: {e}")
print("DONE")
