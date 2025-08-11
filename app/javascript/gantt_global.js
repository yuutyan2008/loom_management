import Gantt from "gantt-fix";

// Expose as global to keep backward compatibility with inline scripts
// that call `new Gantt(...)` without ESM imports.
window.Gantt = Gantt;

