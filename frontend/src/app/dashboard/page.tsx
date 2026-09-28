"use client";

import React, { useMemo } from "react";
import { Card, Row, Col, Statistic } from "antd";
import { TeamOutlined, GlobalOutlined, CrownOutlined } from "@ant-design/icons";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid,
} from "recharts";
import Loader from "@/components/Loader";
import { useSalarySummary } from "@/hooks/useSalaryInsights";

export default function DashboardPage() {
  const summary = useSalarySummary();

  const { totalEmployees, countryCount, topCountry } = useMemo(() => {
    const total = summary.reduce((sum, c) => sum + c.count, 0);
    const top = summary.reduce(
      (best, c) => (!best || c.count > best.count ? c : best),
      summary[0]
    );
    return { totalEmployees: total, countryCount: summary.length, topCountry: top };
  }, [summary]);

  return (
    <div>
      <Row gutter={16} className="stat-strip">
        <Col xs={24} sm={8}>
          <Card className="stat-card">
            <Statistic
              title="Total Employees"
              value={totalEmployees}
              prefix={<TeamOutlined className="stat-card__icon" />}
            />
          </Card>
        </Col>
        <Col xs={24} sm={8}>
          <Card className="stat-card">
            <Statistic
              title="Countries Covered"
              value={countryCount}
              prefix={<GlobalOutlined className="stat-card__icon" />}
            />
          </Card>
        </Col>
        <Col xs={24} sm={8}>
          <Card className="stat-card">
            <Statistic
              title="Largest Workforce"
              value={topCountry?.country || "—"}
              prefix={<CrownOutlined className="stat-card__icon" />}
            />
          </Card>
        </Col>
      </Row>

      <Card title="Headcount by Country" className="section-card">
        {summary.length === 0 ? (
          <Loader />
        ) : (
          <div className="chart-container">
            <ResponsiveContainer width="100%" height={380}>
              <BarChart data={summary}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="country" />
                <YAxis />
                <Tooltip formatter={(value) => `${Number(value).toLocaleString()} employees`} />
                <Bar dataKey="count" name="Employees" fill="#4f46e5" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        )}
      </Card>
    </div>
  );
}
