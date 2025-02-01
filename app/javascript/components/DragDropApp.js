import React, { useState } from "react";
import OrderTable from "./OrderTable";
import DroppableZone from "./DroppableZone";

const initialOrders = [
  { id: 1, company: "A社", product: "ABC-123", color: "Red", startDate: "2024-10-01" },
  { id: 2, company: "B社", product: "XYZ-456", color: "Blue", startDate: "2024-10-05" }
];

const DragDropApp = () => {
  const [orders, setOrders] = useState(initialOrders);
  const [assignedOrders, setAssignedOrders] = useState([]);

  const handleDrop = (order, machineName) => {
    setAssignedOrders([...assignedOrders, { ...order, machineName }]);
    setOrders(orders.filter(o => o.id !== order.id));
  };

  return (
    <div>
      <h1>未割り当ての商品</h1>
      <OrderTable orders={orders} />

      <h1>割り当て済みの商品</h1>
      <DroppableZone machineName="機械A" onDrop={handleDrop} assignedOrders={assignedOrders} />
    </div>
  );
};

export default DragDropApp;
