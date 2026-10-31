# x5 is never written, so it holds an unknown value.
# jalr jumps to x5 + 0, so the PC becomes unknown and stays unknown.
jalr x0, 0(x5)
