import React from "react";
import { useDrop } from "react-dnd";

const DroppableZone = ({ machineName, onDrop, assignedOrders }) => {
  const [{ isOver }, drop] = useDrop(() => ({
    accept: "ORDER",
    drop: (item) => onDrop(item, machineName),
    collect: monitor => ({
      isOver: monitor.isOver()
    })
  }));

  return (
    <div ref={drop} className={`border p-4 ${isOver ? "bg-green-100" : "bg-gray-100"}`}>
      <h2>織機名: {machineName}</h2>
      <table className="w-full border-collapse border border-gray-300">
        <thead>
          <tr>
            <th>ID</th>
            <th>会社名</th>
            <th>品番</th>
            <th>色番</th>
            <th>開始日</th>
            <th>割り当て済み機械</th>
          </tr>
        </thead>
        <tbody>
          {assignedOrders.map((order, index) => (
            <tr key={index} className="hover:bg-gray-50">
              <td className="border px-4 py-2">{order.id}</td>
              <td className="border px-4 py-2">{order.company}</td>
              <td className="border px-4 py-2">{order.product}</td>
              <td className="border px-4 py-2">{order.color}</td>
              <td className="border px-4 py-2">{order.startDate}</td>
              <td className="border px-4 py-2">{order.machineName}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default DroppableZone;
