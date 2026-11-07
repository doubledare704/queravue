function check(n) {
  if (n > 2) throw new Error("too big: " + n);
  return n;
}
check(1);
check(5)
