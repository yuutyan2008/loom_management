import React from "react";
import OrderRow from "./OrderRow";
import { DndProvider } from "react-dnd";
import { HTML5Backend } from "react-dnd-html5-backend";

const OrderTable = ({ orders }) => {
  return (
    <DndProvider backend={HTML5Backend}>
      <table className="table-auto w-full border-collapse border border-gray-300">
        <thead>
          <tr>
            <th>ID</th>
            <th>会社名</th>
            <th>品番</th>
            <th>色番</th>
            <th>開始日</th>
          </tr>
        </thead>
        <tbody>
          {orders.map(order => (
            <OrderRow key={order.id} order={order} />
          ))}
        </tbody>
      </table>
    </DndProvider>
  );
};

export default OrderTable;
