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
import {
  COUNTRY_CURRENCY,
  CHART_CATEGORICAL_COLORS,
  CHART_OTHER_COLOR,
} from "@/constants";

const DISTRIBUTION_SLOT_CAP = CHART_CATEGORICAL_COLORS.length;

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

  const avgSalaryData = useMemo(
    () =>
      summary.map((c) => ({
        country: c.country,
        average_salary: Math.round(c.average_salary),
        currency: COUNTRY_CURRENCY[c.country] || "",
      })),
    [summary]
  );

  const { distributionRow, distributionSegments, distributionTotal } = useMemo(() => {
    const total = summary.reduce((sum, c) => sum + c.count, 0);
    const sorted = [...summary].sort((a, b) => b.count - a.count);
    const head = sorted.slice(0, DISTRIBUTION_SLOT_CAP);
    const tail = sorted.slice(DISTRIBUTION_SLOT_CAP);
    const otherCount = tail.reduce((sum, c) => sum + c.count, 0);

    const segments = head.map((c, i) => ({
      key: c.country,
      count: c.count,
      color: CHART_CATEGORICAL_COLORS[i],
    }));
    if (otherCount > 0) {
      segments.push({ key: "Other", count: otherCount, color: CHART_OTHER_COLOR });
    }

    const row: Record<string, number | string> = { name: "Employees" };
    segments.forEach((s) => {
      row[s.key] = s.count;
    });

    return { distributionRow: [row], distributionSegments: segments, distributionTotal: total };
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

      <Card title="Average Salary by Country" className="section-card">
        {summary.length === 0 ? (
          <Loader />
        ) : (
          <div className="chart-container">
            <ResponsiveContainer width="100%" height={380}>
              <BarChart data={avgSalaryData}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="country" />
                <YAxis />
                <Tooltip
                  formatter={(value, _name, item) =>
                    `${item.payload.currency} ${Number(value).toLocaleString()}`
                  }
                />
                <Bar
                  dataKey="average_salary"
                  name="Average Salary"
                  fill="#0d9488"
                  radius={[6, 6, 0, 0]}
                />
              </BarChart>
            </ResponsiveContainer>
          </div>
        )}
      </Card>

      <Card title="Workforce Distribution by Country" className="section-card">
        {summary.length === 0 ? (
          <Loader />
        ) : (
          <>
            <div className="chart-container">
              <ResponsiveContainer width="100%" height={110}>
                <BarChart
                  data={distributionRow}
                  layout="vertical"
                  margin={{ top: 0, right: 0, bottom: 0, left: 0 }}
                >
                  <XAxis type="number" hide domain={[0, distributionTotal]} />
                  <YAxis type="category" dataKey="name" hide />
                  <Tooltip
                    formatter={(value, name) => [
                      `${Number(value).toLocaleString()} employees (${(
                        (Number(value) / distributionTotal) *
                        100
                      ).toFixed(1)}%)`,
                      name,
                    ]}
                  />
                  {distributionSegments.map((s) => (
                    <Bar key={s.key} dataKey={s.key} stackId="a" fill={s.color} barSize={56} />
                  ))}
                </BarChart>
              </ResponsiveContainer>
            </div>
            <div className="distribution-legend">
              {distributionSegments.map((s) => (
                <span key={s.key} className="distribution-legend__item">
                  <i style={{ background: s.color }} />
                  {s.key} — {((s.count / distributionTotal) * 100).toFixed(1)}%
                </span>
              ))}
            </div>
          </>
        )}
      </Card>
    </div>
  );
}
