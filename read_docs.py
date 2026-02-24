import glob, os

d = r"c:\Users\tonne\SITES\mediare_mgcf\Projeto Mediare Doc"
out_file = r"c:\Users\tonne\SITES\mediare_mgcf\docs_summary.txt"

with open(out_file, "w", encoding="utf-8") as out:
    for f in glob.glob(os.path.join(d, "*.txt")):
        out.write(f"\n\n{'='*20}\nFILE: {os.path.basename(f)}\n{'='*20}\n\n")
        try:
            with open(f, "r", encoding="utf-8") as file:
                content = file.read()
                out.write(content)
        except Exception as e:
            out.write(f"Error reading {f}: {e}")
print("DONE")
