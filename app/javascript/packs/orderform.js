import React, { useEffect, useState } from "react";

// コンポーネント関数定義
const OrderForm = () => {
  // ステートを初期化する

  // 各入力フィールドの値とバリデーション状態を管理するステートの定義
  const [rollCount, setRollCount] = useState(1);
  const [quantity, setQuantity] = useState(1);

  //エラーメッセージを管理するステートの定義
  const [errors, setErrors] = useState({
    company: "",
  });

  // フォーム全体が送信可能かどうかを管理するステート
  // validation管理ステートの定義
  const [isFormValid, setIsFormValid] = useState(false);

  // HTML内に埋め込まれたデータを取得してステートにセット
  // useEffectフックの宣言
  useEffect(() => {
    const rootElement = document.getElementById("order-form-root");
    setRollCount(JSON.parse(rootElement.dataset.roll_count));
    setQuantity(JSON.parse(rootElement.dataset.quantity));
  }, []);

  // validation実施関数の定義
  const validateFields = () => {
    const newErrors = {};

    if (!rollCount || rollCount <= 0)
      newErrors.rollCount = "反数は1以上の値を入力してください。";
    if (!quantity || quantity <= 0)
      newErrors.quantity = "数量は1以上の値を入力してください。";
    if (!startDate) newErrors.startDate = "作業開始日を選択してください。";

    // エラーメッセージ更新関数setErrorsの呼び出し
    setErrors(newErrors);
    // validation状況を更新する関数の呼び出し
    setIsFormValid(Object.keys(newErrors).length === 0);
  };

  // 入力内容のチェックをするイベントハンドラ関数を定義して、その中で更新用関数を呼び出す
  const handleInputChange = (e, setStateFunction) => {
    setStateFunction(e.target.value);
    validateFields(); // 入力が変更されるたびにバリデーション実行
  };
  // 送信イベントハンドラを定義
  const handleSubmit = (e) => {
    e.preventDefault(); // デフォルトのフォーム送信を防止
    validateFields(); // 更新前に全フォームに対し再度バリデーションを実行

    if (isFormValid) {
      alert("フォームが正常に送信されました！");
    }
  };

  return (
    <div>
      <table className="w-full max-w-sm">
        {/* 反数 */}
        <tr className="md:flex md:items-center mb-6">
          <td className="md:w-1/3 py-2">
            <label className="w-1/3 px-4 py-2 text-gray-700 font-bold text-center">
              反数
            </label>
          </td>
          <td className="md:w-2/3">
            <input
              type="number"
              value={rollCount}
              onChange={(e) => handleInputChange(e, setRollCount)}
              min="1"
              placeholder="反数を入力してください"
              className="block w-full rounded-md bg-white px-4 py-2 text-base text-gray-900 border border-gray-300 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm appearance-none"
            />
            {errors.rollCount && (
              <p className="text-red-500">{errors.rollCount}</p>
            )}
          </td>
        </tr>

        {/* 数量 */}
        <tr className="md:flex md:items-center mb-6">
          <td className="md:w-1/3 py-2">
            <label className="w-1/3 px-4 py-2 text-gray-700 font-bold text-center">
              数量
            </label>
          </td>
          <td className="md:w-2/3">
            <input
              type="number"
              value={quantity}
              onChange={(e) => handleInputChange(e, setQuantity)}
              min="1"
              placeholder="数量を入力してください"
              className="block w-full rounded-md bg-white px-4 py-2 text-base text-gray-900 border border-gray-300 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm appearance-none"
            />
            {errors.quantity && (
              <p className="text-red-500">{errors.quantity}</p>
            )}
          </td>
        </tr>
      </table>
    </div>
  );
};

// コンポーネント関数
export default OrderForm;
