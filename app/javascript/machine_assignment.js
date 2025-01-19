import React, { useState } from "react";
import { DragDropContext, Droppable, Draggable } from "react-beautiful-dnd";

const DragAndDropApp = () => {
  // 初期データ
  const [orders, setOrders] = useState([
    { id: "order-1", content: "Order 1" },
    { id: "order-2", content: "Order 2" },
    { id: "order-3", content: "Order 3" },
  ]);

  const [machines, setMachines] = useState([
    { id: "1", name: "ドビー", assignedOrders: [] },
    { id: "2", name: "ジャガード", assignedOrders: [] },
  ]);

  // ドラッグ終了時の処理
  const handleDragEnd = (result) => {
    const { source, destination } = result;

    // ドロップ先がない場合（リスト外にドロップされた場合）
    if (!destination) return;

    // 同じリスト内での並び替え
    if (source.droppableId === destination.droppableId) {
      if (source.droppableId === "orders") {
        const updatedOrders = Array.from(orders);
        const [removed] = updatedOrders.splice(source.index, 1);
        updatedOrders.splice(destination.index, 0, removed);
        setOrders(updatedOrders);
      } else {
        const machineIndex = machines.findIndex(
          (machine) => machine.id === source.droppableId
        );
        const updatedMachines = Array.from(machines);
        const [removed] = updatedMachines[machineIndex].assignedOrders.splice(
          source.index,
          1
        );
        updatedMachines[machineIndex].assignedOrders.splice(
          destination.index,
          0,
          removed
        );
        setMachines(updatedMachines);
      }
    }

    // 異なるリスト間の移動
    if (source.droppableId === "orders") {
      const updatedOrders = Array.from(orders);
      const [removed] = updatedOrders.splice(source.index, 1);

      const machineIndex = machines.findIndex(
        (machine) => machine.id === destination.droppableId
      );
      const updatedMachines = Array.from(machines);
      updatedMachines[machineIndex].assignedOrders.splice(
        destination.index,
        0,
        removed
      );

      setOrders(updatedOrders);
      setMachines(updatedMachines);
    } else {
      const machineIndex = machines.findIndex(
        (machine) => machine.id === source.droppableId
      );
      const updatedMachines = Array.from(machines);
      const [removed] = updatedMachines[machineIndex].assignedOrders.splice(
        source.index,
        1
      );

      const updatedOrders = Array.from(orders);
      updatedOrders.splice(destination.index, 0, removed);

      setOrders(updatedOrders);
      setMachines(updatedMachines);
    }
  };

  return (
    <DragDropContext onDragEnd={handleDragEnd}>
      <div style={{ display: "flex", gap: "20px", padding: "20px" }}>
        {/* Orders List */}
        <Droppable droppableId="orders">
          {(provided) => (
            <div
              {...provided.droppableProps}
              ref={provided.innerRef}
              style={{
                padding: "20px",
                background: "#f0f0f0",
                width: "200px",
                minHeight: "300px",
              }}
            >
              <h3>Orders</h3>
              {orders.map((order, index) => (
                <Draggable key={order.id} draggableId={order.id} index={index}>
                  {(provided) => (
                    <div
                      ref={provided.innerRef}
                      {...provided.draggableProps}
                      {...provided.dragHandleProps}
                      style={{
                        ...provided.draggableProps.style,
                        margin: "10px 0",
                        padding: "10px",
                        background: "white",
                        border: "1px solid #ddd",
                        borderRadius: "5px",
                      }}
                    >
                      {order.content}
                    </div>
                  )}
                </Draggable>
              ))}
              {provided.placeholder}
            </div>
          )}
        </Droppable>

        {/* Machines List */}
        {machines.map((machine) => (
          <Droppable droppableId={machine.id} key={machine.id}>
            {(provided) => (
              <div
                {...provided.droppableProps}
                ref={provided.innerRef}
                style={{
                  padding: "20px",
                  background: "#e8f8e8",
                  width: "200px",
                  minHeight: "300px",
                }}
              >
                <h3>{machine.name}</h3>
                {machine.assignedOrders.map((order, index) => (
                  <Draggable
                    key={order.id}
                    draggableId={order.id}
                    index={index}
                  >
                    {(provided) => (
                      <div
                        ref={provided.innerRef}
                        {...provided.draggableProps}
                        {...provided.dragHandleProps}
                        style={{
                          ...provided.draggableProps.style,
                          margin: "10px 0",
                          padding: "10px",
                          background: "white",
                          border: "1px solid #ddd",
                          borderRadius: "5px",
                        }}
                      >
                        {order.content}
                      </div>
                    )}
                  </Draggable>
                ))}
                {provided.placeholder}
              </div>
            )}
          </Droppable>
        ))}
      </div>
    </DragDropContext>
  );
};

export default DragAndDropApp;
