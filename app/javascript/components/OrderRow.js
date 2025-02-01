import React from "react";
import { useDrag } from "react-dnd";

const OrderRow = ({ order }) => {
  const [{ isDragging }, drag] = useDrag(() => ({
    type: "ORDER",
    item: order,
    collect: monitor => ({
      isDragging: monitor.isDragging()
    })
  }));

  return (
    <tr ref={drag} className={`hover:bg-gray-50 ${isDragging ? "opacity-50" : ""}`}>
      <td className="border px-4 py-2">{order.id}</td>
      <td className="border px-4 py-2">{order.company}</td>
      <td className="border px-4 py-2">{order.product}</td>
      <td className="border px-4 py-2">{order.color}</td>
      <td className="border px-4 py-2">{order.startDate}</td>
    </tr>
  );
};

export default OrderRow;
