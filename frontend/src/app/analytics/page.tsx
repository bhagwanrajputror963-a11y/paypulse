"use client";

import React, { useState } from "react";
import { Card, Select, Statistic, Row, Col, Table, Empty } from "antd";
import {
  ArrowDownOutlined,
  ArrowUpOutlined,
  BarChartOutlined,
  DollarCircleOutlined,
  TeamOutlined,
} from "@ant-design/icons";
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from "recharts";
import Loader from "@/components/Loader";
import { useCountryInsights, useSalarySummary } from "@/hooks/useSalaryInsights";
import { COUNTRIES, COUNTRY_CURRENCY, JOB_TITLES } from "@/constants";
import type { CountryOverview } from "@/types";

export default function AnalyticsPage() {
  const [country, setCountry] = useState<string>("India");
  const [jobTitle, setJobTitle] = useState<string>("Engineer");

  const currency = COUNTRY_CURRENCY[country] || "USD";

  const summary = useSalarySummary();
  const { stats, titles, loading } = useCountryInsights(country);
  const jobTitleAvg = titles.find((t) => t.job_title === jobTitle)?.average_salary ?? null;

  const overviewColumns = [
    { title: "Country", dataIndex: "country", key: "country" },
    { title: "Employees", dataIndex: "count", key: "count" },
    {
      title: "Avg Salary",
      dataIndex: "average_salary",
      key: "average_salary",
      render: (val: number, record: CountryOverview) =>
        `${COUNTRY_CURRENCY[record.country] || ""} ${val.toLocaleString()}`,
    },
  ];

  return (
    <div>
      <div className="page-header page-header--analytics">
        <span className="page-header__label"><BarChartOutlined /> Country</span>
        <Select
          value={country}
          onChange={setCountry}
          className="filter-select"
          options={COUNTRIES.map((c) => ({ label: c, value: c }))}
        />
      </div>

      {loading ? (
        <Loader />
      ) : (
        <>
          <Card title={`Salary Statistics — ${country}`} className="section-card">
            {stats && stats.count > 0 ? (
              <Row gutter={16}>
                <Col xs={12} md={6}>
                  <Statistic
                    title="Minimum Salary"
                    value={stats.min}
                    prefix={<ArrowDownOutlined className="stat-card__icon stat-card__icon--down" />}
                    suffix={currency}
                  />
                </Col>
                <Col xs={12} md={6}>
                  <Statistic
                    title="Maximum Salary"
                    value={stats.max}
                    prefix={<ArrowUpOutlined className="stat-card__icon stat-card__icon--up" />}
                    suffix={currency}
                  />
                </Col>
                <Col xs={12} md={6}>
                  <Statistic
                    title="Average Salary"
                    value={stats.average}
                    precision={2}
                    prefix={<DollarCircleOutlined className="stat-card__icon" />}
                    suffix={currency}
                  />
                </Col>
                <Col xs={12} md={6}>
                  <Statistic
                    title="Total Employees"
                    value={stats.count}
                    prefix={<TeamOutlined className="stat-card__icon" />}
                  />
                </Col>
              </Row>
            ) : (
              <Empty description={`No employees found in ${country}`} />
            )}
          </Card>

          <Card title={`Average Salary by Job Title — ${country}`} className="section-card">
            <div className="filter-row">
              <Select
                value={jobTitle}
                onChange={setJobTitle}
                className="filter-select"
                options={JOB_TITLES.map((t) => ({ label: t, value: t }))}
              />
            </div>

            {jobTitleAvg !== null ? (
              <Statistic title={`${jobTitle} in ${country}`} value={jobTitleAvg} prefix={currency} precision={2} />
            ) : (
              <Empty description={`No ${jobTitle} employees in ${country}`} />
            )}

            {titles.length > 0 && (
              <div className="chart-container">
                <ResponsiveContainer width="100%" height={350}>
                  <BarChart data={titles} margin={{ bottom: 48 }}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis
                      dataKey="job_title"
                      interval={0}
                      angle={-35}
                      textAnchor="end"
                      height={60}
                      tick={{ fontSize: 12 }}
                    />
                    <YAxis />
                    <Tooltip formatter={(value) => `${currency} ${Number(value).toLocaleString()}`} />
                    <Bar dataKey="average_salary" fill="#4f46e5" radius={[6, 6, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}
          </Card>
        </>
      )}

      <Card title="Salary Summary by Country">
        <Table
          dataSource={summary}
          columns={overviewColumns}
          rowKey="country"
          pagination={false}
        />
      </Card>
    </div>
  );
}
