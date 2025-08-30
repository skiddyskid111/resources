import tkinter as tk
from tkinter import messagebox

root = tk.Tk()
root.withdraw()
root.attributes('-topmost', True)
messagebox.showerror('Error', 'License invalid')
root.destroy()
