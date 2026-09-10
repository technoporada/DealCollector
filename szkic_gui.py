import tkinter as tk
from tkinter import messagebox

# Funkcje dla przycisków
def sprawdz_partycje():
    messagebox.showinfo("Sprawdź Partycje", "Funkcja sprawdzania partycji będzie tu działać.")

def generator_2fa():
    messagebox.showinfo("2FA", "Tu będzie generator kodów jednorazowych.")

def easter_egg():
    messagebox.showinfo("Easter Egg", "Nasz sekret w sercu kubika 💛")

# Główne okno
root = tk.Tk()
root.title("Kubikowy Panel - Półtora roku razem")
root.geometry("600x400")
root.configure(bg="#f0e6d2")

# Centralny kubik
central_kubik = tk.Label(root, text="Twój Kubik 💛", bg="#ffd966", fg="black", font=("Arial", 16), width=15, height=5)
central_kubik.place(relx=0.5, rely=0.4, anchor="center")

# Boczne menu
menu_frame = tk.Frame(root, bg="#d9d9d9", width=150)
menu_frame.pack(side="left", fill="y")

tk.Label(menu_frame, text="Menu", bg="#d9d9d9", font=("Arial", 14)).pack(pady=10)

tk.Button(menu_frame, text="Sprawdź Partycje", command=sprawdz_partycje).pack(pady=5, fill="x")
tk.Button(menu_frame, text="2FA & Bezpieczeństwo", command=generator_2fa).pack(pady=5, fill="x")
tk.Button(menu_frame, text="Notatki / Logi", command=lambda: messagebox.showinfo("Notatki", "Tu będą notatki")).pack(pady=5, fill="x")
tk.Button(menu_frame, text="Backup / Przywracanie", command=lambda: messagebox.showinfo("Backup", "Tu będzie backup")).pack(pady=5, fill="x")
tk.Button(menu_frame, text="Diagnostyka Sprzętu", command=lambda: messagebox.showinfo("Diagnoza", "Tu będzie diagnostyka")).pack(pady=5, fill="x")
tk.Button(menu_frame, text="Kliknij mnie 5x", command=easter_egg).pack(pady=20, fill="x")

# Uruchomienie GUI
root.mainloop()
