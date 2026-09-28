"use client";

import React from "react";
import { ConfigProvider, Layout, Menu, theme as antdTheme } from "antd";
import { TeamOutlined, BarChartOutlined, ThunderboltFilled, DashboardOutlined } from "@ant-design/icons";
import { useRouter, usePathname } from "next/navigation";
import { ROUTES } from "@/constants";

const { Header, Content } = Layout;

const menuItems = [
  { key: ROUTES.DASHBOARD, icon: <DashboardOutlined />, label: "Dashboard" },
  { key: ROUTES.EMPLOYEES, icon: <TeamOutlined />, label: "Employees" },
  { key: ROUTES.ANALYTICS, icon: <BarChartOutlined />, label: "Salary Insights" },
];

const PAGE_TITLES: { match: (path: string) => boolean; title: string; subtitle: string }[] = [
  {
    match: (path) => path === ROUTES.DASHBOARD,
    title: "Dashboard",
    subtitle: "Organization-wide headcount and pay overview",
  },
  {
    match: (path) => path === ROUTES.EMPLOYEES,
    title: "Employees",
    subtitle: "Manage employee records across the organization",
  },
  {
    match: (path) => path.startsWith("/employees/"),
    title: "Employee Profile",
    subtitle: "Detailed view of a single employee",
  },
  {
    match: (path) => path === ROUTES.ANALYTICS,
    title: "Salary Insights",
    subtitle: "Pay trends and comparisons across countries and roles",
  },
];

function pageMeta(pathname: string) {
  return (
    PAGE_TITLES.find((entry) => entry.match(pathname)) || {
      title: "PayPulse",
      subtitle: "",
    }
  );
}

export default function AppShell({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const { title, subtitle } = pageMeta(pathname);

  return (
    <ConfigProvider
      theme={{
        token: {
          colorPrimary: "#0d9488",
          borderRadius: 10,
          fontFamily: "inherit",
        },
        algorithm: antdTheme.defaultAlgorithm,
      }}
    >
      <Layout className="app-layout">
        <Header className="app-topbar">
          <div className="app-brand">
            <ThunderboltFilled className="app-brand__icon" />
            <span className="app-brand__name">PayPulse</span>
          </div>
          <Menu
            mode="horizontal"
            selectedKeys={[pathname]}
            items={menuItems}
            onClick={({ key }) => router.push(key)}
            className="app-topnav"
          />
        </Header>
        <div className="app-page-banner">
          <h1 className="app-page-banner__title">{title}</h1>
          {subtitle && <p className="app-page-banner__subtitle">{subtitle}</p>}
        </div>
        <Content className="app-content">{children}</Content>
      </Layout>
    </ConfigProvider>
  );
}
