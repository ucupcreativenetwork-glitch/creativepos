export function printElementById(elementId: string): boolean {
  const element = document.getElementById(elementId);
  if (!element) return false;

  const printWindow = window.open("", "_blank", "width=400,height=700");
  if (!printWindow) {
    window.alert("Izinkan pop-up browser untuk mencetak struk.");
    return false;
  }

  printWindow.document.write(`<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Struk</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: "Courier New", Courier, monospace;
      font-size: 12px;
      line-height: 1.4;
      padding: 12px;
      color: #111;
      max-width: 80mm;
      margin: 0 auto;
    }
    .text-center { text-align: center; }
    .font-semibold { font-weight: 600; }
    .text-sm { font-size: 13px; }
    .text-xs, .text-\\[10px\\], .text-\\[11px\\] { font-size: 10px; }
    .text-muted-foreground { color: #666; }
    .border-t { border-top: 1px dashed #ccc; }
    .pt-3 { padding-top: 12px; }
    .mt-2 { margin-top: 8px; }
    .mb-3 { margin-bottom: 12px; }
    .space-y-1 > * + * { margin-top: 4px; }
    .space-y-4 > * + * { margin-top: 16px; }
    .flex { display: flex; }
    .justify-between { justify-content: space-between; }
    .gap-2 { gap: 8px; }
    .font-medium { font-weight: 500; }
    .font-bold { font-weight: 700; }
    .uppercase { text-transform: uppercase; }
    .tracking-widest { letter-spacing: 0.1em; }
    ul { list-style: none; padding-left: 4px; }
    @media print {
      body { padding: 0; }
    }
  </style>
</head>
<body>${element.innerHTML}</body>
</html>`);
  printWindow.document.close();
  printWindow.focus();
  printWindow.print();
  printWindow.close();

  return true;
}