namespace WindowsForms
{
    partial class DataEntryForm
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            System.Windows.Forms.ListViewItem listViewItem1 = new System.Windows.Forms.ListViewItem(new string[] {
            "John Doe",
            "12/15/1967",
            "FL"}, -1);
            System.Windows.Forms.ListViewItem listViewItem2 = new System.Windows.Forms.ListViewItem(new string[] {
            "Anna Doe",
            "3/4/1975"}, -1);
            this.deleteItemButton = new System.Windows.Forms.Button();
            this.groupBox3 = new System.Windows.Forms.GroupBox();
            this.addItemButton = new System.Windows.Forms.Button();
            this.personListView = new System.Windows.Forms.ListView();
            this.columnName = ((System.Windows.Forms.ColumnHeader)(new System.Windows.Forms.ColumnHeader()));
            this.columnDateOfBirth = ((System.Windows.Forms.ColumnHeader)(new System.Windows.Forms.ColumnHeader()));
            this.columnState = ((System.Windows.Forms.ColumnHeader)(new System.Windows.Forms.ColumnHeader()));
            this.closeDataEntryFormButton = new System.Windows.Forms.Button();
            this.maskedTextBox1 = new System.Windows.Forms.MaskedTextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.maskedTextBox2 = new System.Windows.Forms.MaskedTextBox();
            this.groupBox3.SuspendLayout();
            this.SuspendLayout();
            // 
            // deleteItemButton
            // 
            this.deleteItemButton.Location = new System.Drawing.Point(334, 55);
            this.deleteItemButton.Name = "deleteItemButton";
            this.deleteItemButton.Size = new System.Drawing.Size(75, 23);
            this.deleteItemButton.TabIndex = 2;
            this.deleteItemButton.Text = "Delete";
            this.deleteItemButton.UseVisualStyleBackColor = true;
            this.deleteItemButton.Click += new System.EventHandler(this.deleteItemButton_Click);
            // 
            // groupBox3
            // 
            this.groupBox3.Controls.Add(this.deleteItemButton);
            this.groupBox3.Controls.Add(this.addItemButton);
            this.groupBox3.Controls.Add(this.personListView);
            this.groupBox3.Location = new System.Drawing.Point(135, 12);
            this.groupBox3.Name = "groupBox3";
            this.groupBox3.Size = new System.Drawing.Size(415, 114);
            this.groupBox3.TabIndex = 9;
            this.groupBox3.TabStop = false;
            this.groupBox3.Text = "List of items";
            // 
            // addItemButton
            // 
            this.addItemButton.Location = new System.Drawing.Point(334, 26);
            this.addItemButton.Name = "addItemButton";
            this.addItemButton.Size = new System.Drawing.Size(75, 23);
            this.addItemButton.TabIndex = 1;
            this.addItemButton.Text = "Add ...";
            this.addItemButton.UseVisualStyleBackColor = true;
            this.addItemButton.Click += new System.EventHandler(this.addItemButton_Click);
            // 
            // personListView
            // 
            this.personListView.Columns.AddRange(new System.Windows.Forms.ColumnHeader[] {
            this.columnName,
            this.columnDateOfBirth,
            this.columnState});
            this.personListView.GridLines = true;
            this.personListView.HeaderStyle = System.Windows.Forms.ColumnHeaderStyle.Nonclickable;
            this.personListView.Items.AddRange(new System.Windows.Forms.ListViewItem[] {
            listViewItem1,
            listViewItem2});
            this.personListView.Location = new System.Drawing.Point(6, 26);
            this.personListView.Name = "personListView";
            this.personListView.Size = new System.Drawing.Size(314, 74);
            this.personListView.TabIndex = 0;
            this.personListView.UseCompatibleStateImageBehavior = false;
            this.personListView.View = System.Windows.Forms.View.Details;
            // 
            // columnName
            // 
            this.columnName.Text = "Name";
            this.columnName.Width = 148;
            // 
            // columnDateOfBirth
            // 
            this.columnDateOfBirth.Text = "Date of birth";
            this.columnDateOfBirth.Width = 100;
            // 
            // columnState
            // 
            this.columnState.Text = "State";
            // 
            // closeDataEntryFormButton
            // 
            this.closeDataEntryFormButton.Location = new System.Drawing.Point(12, 12);
            this.closeDataEntryFormButton.Name = "closeDataEntryFormButton";
            this.closeDataEntryFormButton.Size = new System.Drawing.Size(95, 23);
            this.closeDataEntryFormButton.TabIndex = 11;
            this.closeDataEntryFormButton.Text = "Close";
            this.closeDataEntryFormButton.UseVisualStyleBackColor = true;
            this.closeDataEntryFormButton.Click += new System.EventHandler(this.closeDataEntryFormButton_Click);
            // 
            // maskedTextBox1
            // 
            this.maskedTextBox1.Location = new System.Drawing.Point(254, 147);
            this.maskedTextBox1.Mask = "(999) 000-0000";
            this.maskedTextBox1.Name = "maskedTextBox1";
            this.maskedTextBox1.Size = new System.Drawing.Size(100, 20);
            this.maskedTextBox1.TabIndex = 12;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(138, 150);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(76, 13);
            this.label1.TabIndex = 13;
            this.label1.Text = "Phone number";
            // 
            // maskedTextBox2
            // 
            this.maskedTextBox2.Location = new System.Drawing.Point(425, 280);
            this.maskedTextBox2.Mask = "00/00/0000";
            this.maskedTextBox2.Name = "maskedTextBox2";
            this.maskedTextBox2.Size = new System.Drawing.Size(100, 20);
            this.maskedTextBox2.TabIndex = 14;
            this.maskedTextBox2.ValidatingType = typeof(System.DateTime);
            // 
            // DataEntryForm
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(724, 474);
            this.Controls.Add(this.maskedTextBox2);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.maskedTextBox1);
            this.Controls.Add(this.closeDataEntryFormButton);
            this.Controls.Add(this.groupBox3);
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "DataEntryForm";
            this.ShowInTaskbar = false;
            this.Text = "DataEntryForm";
            this.groupBox3.ResumeLayout(false);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button deleteItemButton;
        private System.Windows.Forms.GroupBox groupBox3;
        private System.Windows.Forms.Button addItemButton;
        private System.Windows.Forms.ListView personListView;
        private System.Windows.Forms.ColumnHeader columnName;
        private System.Windows.Forms.ColumnHeader columnDateOfBirth;
        private System.Windows.Forms.Button closeDataEntryFormButton;
        private System.Windows.Forms.MaskedTextBox maskedTextBox1;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.ColumnHeader columnState;
        private System.Windows.Forms.MaskedTextBox maskedTextBox2;
    }
}